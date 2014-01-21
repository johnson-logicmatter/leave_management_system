class Employee < User
  unloadable
  self.inheritance_column = :_type_disabled

  has_many :lms_yearly_leave_histories, :foreign_key => :user_id
  has_one :current_year_leave_history, :class_name => "LmsYearlyLeaveHistory", :include => [:lms_yearly_setting], :conditions => "lms_yearly_settings.year = YEAR(NOW())", :foreign_key => :user_id
  has_many :lms_monthly_leave_histories, :foreign_key => :user_id
  has_one :current_month_leave_history, :class_name => "LmsMonthlyLeaveHistory", :include => [:lms_yearly_leave_history => :lms_yearly_setting], :conditions => "month = Month(NOW()) AND lms_yearly_settings.year = YEAR(NOW())", :foreign_key => :user_id
  has_many :lms_leaves, :class_name => "LmsLeave", :foreign_key => :user_id
  
  def self.current
    User.current.becomes(self)
  end
  def type
    'User'
  end
  
  def leave_history(leave_types, year = Date.today.year, month = Date.today.month, r_period = LmsLeaveType::YEAR)
    leaves = ''
    leave_types.each {|lt| leaves << "IFNULL(SUM(m.ded_#{lt}), 0) AS ded_#{lt}, "}
    yearly_history = lms_yearly_leave_histories.find :first, :joins => :lms_yearly_setting, :conditions => ["year = ?", year]
    return nil unless yearly_history
    join_condition = case r_period
      when :y
        monthly_hist_count = yearly_history.lms_monthly_leave_histories.find(:all, :conditions => ["month <= ?", month]).count
        "m.month <= #{month}"
      when :m
        monthly_hist_count = yearly_history.lms_monthly_leave_histories.find(:all, :conditions => ["month = ?", month]).count
        "m.month = #{month}"
      when :q
        monthly_hist_count = yearly_history.lms_monthly_leave_histories.find(:all, :conditions => ["month <= ?", month]).count
        "m.month <= #{month}"
    end
    return nil if monthly_hist_count == 0
    lms_yearly_leave_histories.find(:first, :joins => "JOIN users u ON lms_yearly_leave_histories.user_id = u.id INNER JOIN lms_yearly_settings s ON lms_yearly_leave_histories.lms_yearly_setting_id = s.id INNER JOIN lms_monthly_leave_histories m ON lms_yearly_leave_histories.id = m.lms_yearly_leave_history_id AND #{join_condition}", :conditions => ["year = ?", year], :select => "CONCAT(u.firstname,' ', u.lastname) AS emp_name, lms_yearly_leave_histories.*, tot_wfh * #{monthly_hist_count} AS acc_wfh, IFNULL(sum(m.ded_carry_forward), 0.0) AS ded_carry_forward, #{leaves} IFNULL(sum(m.lop), 0.0) AS lop, IFNULL(sum(m.ded_wfh), 0.0) AS ded_wfh, IFNULL(sum(m.total_leaves_taken), 0.0) AS total_leaves_taken")
  end
    
  def previous_year_leave_history
    lms_yearly_leave_histories.find(:first, :joins => "LEFT JOIN lms_yearly_settings s ON lms_yearly_leave_histories.lms_yearly_setting_id = s.id LEFT JOIN lms_monthly_leave_histories m ON lms_yearly_leave_histories.id = m.lms_yearly_leave_history_id", :conditions => ["year = ?", Date.today.year - 1], :select => "IFNULL(lms_yearly_leave_histories.total_leaves, 0) AS total_leaves, IFNULL(sum(m.total_leaves_taken), 0) AS leaves_taken, (IFNULL(lms_yearly_leave_histories.total_leaves, 0) - IFNULL(sum(m.total_leaves_taken), 0)) AS available_leaves")
  end
  
  def self.pending_leaves
    self.current.lms_leaves.find(:all, :joins => [:lms_leave_status, :lms_yearly_leave_history => :lms_yearly_setting], 
						:conditions => ["status = ? AND year = YEAR(NOW())", LmsLeaveStatus::PENDING], 
						:select => "lms_leaves.id AS id, #{LmsLeave.select_column_names_excluding_id}, lms_leave_statuses.id AS lms_leave_status_id, #{LmsLeaveStatus.select_column_names_excluding_id}", 
						:order => "from_date ASC, to_date ASC")
  end
  
  def self.approved_leaves
    self.current.lms_leaves.find(:all, :joins => [:lms_leave_status, :lms_yearly_leave_history => :lms_yearly_setting], 
						:conditions => ["status = ? AND year = YEAR(NOW())", LmsLeaveStatus::APPROVED], 
						:select => "lms_leaves.id AS id, #{LmsLeave.select_column_names_excluding_id}, lms_leave_statuses.id AS lms_leave_status_id, #{LmsLeaveStatus.select_column_names_excluding_id}", 
						:order => "from_date ASC, to_date ASC")
  end

  def self.processed_leaves
    self.current.lms_leaves.find(:all, :joins => [:lms_leave_status, :lms_yearly_leave_history => :lms_yearly_setting], 
						:conditions => ["status = ? AND year = YEAR(NOW())", LmsLeaveStatus::PROCESSED], 
						:select => "lms_leaves.id AS id, #{LmsLeave.select_column_names_excluding_id}, lms_leave_statuses.id AS lms_leave_status_id, #{LmsLeaveStatus.select_column_names_excluding_id}", 
						:order => "from_date ASC, to_date ASC")
  end

  def self.approved_and_processed_leaves
    self.current.lms_leaves.find(:all, :joins => [:lms_leave_status, :lms_yearly_leave_history => :lms_yearly_setting], 
						:conditions => ["(status = ? OR status = ?) AND year = YEAR(NOW())", LmsLeaveStatus::APPROVED, LmsLeaveStatus::PROCESSED], 
						:select => "lms_leaves.id AS id, #{LmsLeave.select_column_names_excluding_id}, lms_leave_statuses.id AS lms_leave_status_id, #{LmsLeaveStatus.select_column_names_excluding_id}", 
						:order => "status ASC, from_date ASC, to_date ASC")
  end
  
  def self.rejected_leaves
    self.current.lms_leaves.find(:all, :joins => [:lms_leave_status, :lms_yearly_leave_history => :lms_yearly_setting], 
						:conditions => ["status = ? AND year = YEAR(NOW())", LmsLeaveStatus::REJECTED], 
						:select => "lms_leaves.id AS id, #{LmsLeave.select_column_names_excluding_id}, lms_leave_statuses.id AS lms_leave_status_id, #{LmsLeaveStatus.select_column_names_excluding_id}", 
						:order => "from_date ASC, to_date ASC")	  
  end
  
  def self.cancelled_leaves
    self.current.lms_leaves.find(:all, :joins => [:lms_leave_status, :lms_yearly_leave_history => :lms_yearly_setting], 
						:conditions => ["status = ? AND year = YEAR(NOW())", LmsLeaveStatus::CANCELLED], 
						:select => "lms_leaves.id AS id, #{LmsLeave.select_column_names_excluding_id}, lms_leave_statuses.id AS lms_leave_status_id, #{LmsLeaveStatus.select_column_names_excluding_id}", 
						:order => "from_date ASC, to_date ASC")	  
  end
  
  def leaves(year = Date.today.year, month = Date.today.month, status = LmsLeaveStatus::PROCESSED, r_period = LmsLeaveType::YEAR, l_type = LmsLeave::ALL)
    query_cond = ["leave_category_id IN (?) AND year = ? AND "]
    query_cond[0] << case r_period
      when :y
        "month <= ? AND "
      when :m
        "month = ? AND "
      when :q
        "month <= ? AND "
    end
    query_cond[0] << "(parent_leave_id IS NULL OR parent_leave_id <> #{LmsLeave.table_name}.id) AND #{LmsLeaveStatus.table_name}.status IN (?)"
    query_cond << case l_type
      when :all
        LmsLeaveCategory.all.keys
      when :leave
        LmsLeaveCategory::LEAVE_CATEGORIES.keys
      when :wfh
        LmsLeaveCategory::WORK_FROM_HOME.keys
    end
    query_cond << year << month << status
    lms_leaves.find(:all, :joins => [:lms_monthly_leave_history, :lms_leave_status, :lms_yearly_leave_history => :lms_yearly_setting], 
				:conditions => query_cond, 
				:select => "#{LmsLeave.table_name}.id AS id, #{LmsLeave.select_column_names_excluding_id}, #{LmsLeaveStatus.table_name}.id AS lms_leave_status_id, #{LmsLeaveStatus.select_column_names_excluding_id}", 
				:order => "from_date ASC, to_date ASC")
  end
end