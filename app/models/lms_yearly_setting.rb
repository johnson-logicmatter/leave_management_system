class LmsYearlySetting < ActiveRecord::Base
  unloadable
  has_many :lms_yearly_leave_histories, :dependent => :destroy
  has_many :lms_public_holidays, :dependent => :destroy
  has_and_belongs_to_many :leave_types, :class_name => 'LmsLeaveType'
  
  def self.current_year_settings
    self.find :first, :conditions => ["year = YEAR(NOW())"]
  end
  
  def started?
    self.started
  end
  
  def update_leave_type(leave_type)
    self.update_attribute "tot_#{leave_type.identifier}".to_sym, leave_type.days
    ActiveRecord::Base.connection.execute("UPDATE lms_yearly_leave_histories SET tot_#{leave_type.identifier} = #{leave_type.days} WHERE lms_yearly_setting_id = #{self.id};")
    ActiveRecord::Base.connection.close
    LmsYearlyLeaveHistory.update_total_leaves(self)
  end

  def clear_leave_type(leave_type)
    self.update_attribute "tot_#{leave_type.identifier}".to_sym, 0
    ActiveRecord::Base.connection.execute("UPDATE lms_yearly_leave_histories SET tot_#{leave_type.identifier} = 0 WHERE lms_yearly_setting_id = #{self.id};")
    ActiveRecord::Base.connection.close
    LmsYearlyLeaveHistory.update_total_leaves(self)
  end

  def update_work_from_home(lms_settings)
    self.update_attributes :work_from_home => true, :work_from_home_limit => lms_settings.work_from_home_limit
    raw_sql = "UPDATE lms_yearly_leave_histories SET tot_wfh = #{lms_settings.work_from_home_limit} WHERE lms_yearly_setting_id = #{self.id};"
    ActiveRecord::Base.connection.execute(raw_sql)
    ActiveRecord::Base.connection.close
  end
  
  def clear_work_from_home
    self.update_attributes :work_from_home => false, :work_from_home_limit => 0
    raw_sql = "UPDATE lms_yearly_leave_histories SET tot_wfh = 0 WHERE lms_yearly_setting_id = #{self.id};"
    ActiveRecord::Base.connection.execute(raw_sql)
    ActiveRecord::Base.connection.close
  end

  def update_carry_forward(lms_settings)
    self.update_attributes :carry_forward => true, :carry_forward_limit => lms_settings.max_days
    employees = LeaveManagementSystem.active_employees_with_role LeaveManagementSystem::ROLES[:al]
    employees.each do |e|
      prev_year_leave_history = e.previous_year_leave_history
      carry_forward = prev_year_leave_history.available_leaves > lms_settings.max_days ? lms_settings.max_days : prev_year_leave_history.available_leaves
      cur_year_leave_history = e.current_year_leave_history
      cur_year_leave_history.update_attribute :tot_carry_forward, carry_forward
    end
    LmsYearlyLeaveHistory.update_total_leaves(self)
  end
  
  def clear_carry_forward
    self.update_attributes :carry_forward => false, :carry_forward_limit => 0
    raw_sql = "UPDATE lms_yearly_leave_histories SET tot_carry_forward = 0 WHERE lms_yearly_setting_id = #{self.id};"
    ActiveRecord::Base.connection.execute(raw_sql)
    ActiveRecord::Base.connection.close
    LmsYearlyLeaveHistory.update_total_leaves(self)
  end
end