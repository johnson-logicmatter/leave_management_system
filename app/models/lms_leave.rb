class LmsLeave < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes
  ALL = :all
  LEAVE = :leave
  WFH = :wfh
  
  has_one :lms_leave_category
  has_one :lms_leave_status, :dependent => :destroy
  has_many :split_leaves, :class_name => 'LmsLeave', :foreign_key => 'parent_leave_id', :conditions => ["lms_leaves.id <> parent_leave_id"]
  belongs_to :parent_leave, :class_name => 'LmsLeave', :foreign_key => 'parent_leave_id'
  belongs_to :lms_yearly_leave_history
  belongs_to :lms_monthly_leave_history
  belongs_to :employee, :foreign_key => 'user_id'
  
  delegate :approver, :rejector, :processor, :to => :lms_leave_status
  delegate :lms_yearly_setting, :to => :lms_yearly_leave_history
  
  scope :not_processed, :joins => [:lms_leave_status], :conditions => ["status <> ?", LmsLeaveStatus::PROCESSED]
  
  serialize :reported_to
  serialize :leave_dates_object
  
  validates_presence_of :reported_to, :from_date, :to_date, :no_of_days, :reason
  validates :no_of_days, :numericality => { :greater_than => 0 }
  validate :validate_notificants, :if => Proc.new {|leave| leave.notificants.present?}
  validate :validate_from_and_to_date, :if => Proc.new {|leave| leave.from_date.present? && leave.to_date.present?}
  validate :validate_leave_dates_object, :if => Proc.new {|leave| leave.leave_dates_object.present?}
  validate :check_public_holidays, :if => Proc.new {|leave| leave.leave_dates_object.present?}
  
  after_create :create_leave_status
  after_create :notify
  safe_attributes 'leave_category_id', 'reported_to', 'notificants', 'from_date', 'to_date', 'no_of_days', 'reason', 'leave_dates_object'
  
  def pending?
    status == LmsLeaveStatus::PENDING
  end
  
  def approved?
    status == LmsLeaveStatus::APPROVED
  end

  def processed?
    status == LmsLeaveStatus::PROCESSED
  end
  
  def rejected?
    status == LmsLeaveStatus::REJECTED
  end

  def cancelled?
    status == LmsLeaveStatus::CANCELLED
  end
  
  def self.pending_leaves
    filter_leaves(fetch_leaves(:pending))
  end
  
  def self.approved_leaves
    filter_leaves(fetch_leaves(:approved))
  end

  def self.processed_leaves
    filter_leaves(fetch_leaves(:processed))
  end

  def self.approved_and_processed_leaves
    filter_leaves(fetch_leaves(:approved_and_processed))
  end
  
  def self.rejected_leaves
    filter_leaves(fetch_leaves(:rejected))
  end

  def self.cancelled_leaves
    filter_leaves(fetch_leaves(:cancelled))
  end
    
  def approver_name
    self.approver.name
  end
  
  def processor_name
    self.processor.name
  end
  
  def rejector_name
    self.rejector.name
  end
  
  def reportees
    Employee.where("id IN (?)", self.reported_to).map(&:name).join(', ')
  end
  
  def parse_leave_dates_objects
    parsed_leave_dates_objects = {}
    self.leave_dates_object.each do |d|
      if parsed_leave_dates_objects.has_key? d.to_date.month
     	parsed_leave_dates_objects[d.to_date.month] << d
      else
     	parsed_leave_dates_objects[d.to_date.month] = [d]
      end
    end
    return parsed_leave_dates_objects    
  end
  
  def full_days
    self.leave_dates_object.select {|date| date.match(/ :F$/)}.map {|date| date.to_date.strftime("%d %b %Y")}.join(', ')	  
  end
  
  def half_days
    self.leave_dates_object.select {|date| date.match(/ :H$/)}.map {|date| date.to_date.strftime("%d %b, %Y")}.join(', ')
  end
  
  private
  def notify
    if self.parent_leave_id.nil?
      Mailer.apply_leave(self).deliver
    end	  
  end
  
  def create_leave_status
    if self.parent_leave_id.present?
      parent_leave_status = self.parent_leave.lms_leave_status
      self.build_lms_leave_status(:status => LmsLeaveStatus::APPROVED, :approved_by => parent_leave_status.approved_by, :approved_on => parent_leave_status.approved_on).save
    else
      self.build_lms_leave_status.save
    end
  end
  
  def validate_from_and_to_date
    yr_start_date = Date.new(Date.today.year, 1, 1)
    yr_end_date = Date.new(Date.today.year, 12, 31)
    self.from_date = self.from_date.to_date
    self.to_date = self.to_date.to_date
    self.errors.add(:base, "Apply leaves between #{yr_start_date.strftime('%d %b, %Y')} - #{yr_end_date.strftime('%d %b, %Y')} only") unless self.from_date.between?(yr_start_date, yr_end_date) && self.to_date.between?(yr_start_date, yr_end_date)
    self.errors.add(:to_date, "should not be less than from date") if self.from_date.between?(yr_start_date, yr_end_date) && self.to_date.between?(yr_start_date, yr_end_date) && self.to_date < self.from_date
  end
  
  def validate_leave_dates_object
    employee = Employee.current
    exist_leav_recs = employee.current_year_leave_history.lms_leaves.find :all, :joins =>:lms_leave_status, :conditions => ["(parent_leave_id IS NULL OR lms_leaves.id = parent_leave_id) AND (status IN (?))", [LmsLeaveStatus::PENDING, LmsLeaveStatus::APPROVED, LmsLeaveStatus::PROCESSED]]
    already_app_leav_dates = exist_leav_recs.map(&:leave_dates_object).flatten
    reapplied_dates = already_app_leav_dates.select { |adate| self.leave_dates_object.find { |ndate| ndate.to_date == adate.to_date } }
    if LmsLeaveCategory::WORK_FROM_HOME[self.leave_category_id.to_i]
      parsed_leave_dates_objects = self.parse_leave_dates_objects
      max_allowed_wfh = employee.current_year_leave_history.tot_wfh
      parsed_leave_dates_objects.each do |month, dates|
        already_app_wfh = employee.leaves(Date.today.year, month, [LmsLeaveStatus::PENDING, LmsLeaveStatus::APPROVED, LmsLeaveStatus::PROCESSED], LmsLeaveType::MONTH, LmsLeave::WFH).sum(&:no_of_days)
	allowed_wfh = max_allowed_wfh - already_app_wfh
	ndays = dates.map {|date| date.match(/ :H$/) ? 0.5 : 1}.sum
	self.errors.add(:base, "Your available work from home for the #{Date.new(Date.today.year, month).strftime('%B')} month is #{allowed_wfh} day(s) only") if allowed_wfh < ndays
      end
    end
    if reapplied_dates.present?
      full_days = reapplied_dates.select { |date| date.match(/ :F$/) }
      temp = reapplied_dates - full_days
      full_days = (full_days << temp.select {|date| temp.count(date)  > 1 }.uniq).flatten.sort
      half_days = (reapplied_dates - full_days).select { |hdate| self.leave_dates_object.find { |ndate| ndate.to_date == hdate.to_date && ndate.match(/ :F$/) } }.sort
      if full_days.present? || half_days.present?
     	message = "You are trying to apply leaves/work from home on some dates which you were taken/applied already. Please check those dates!"
     	message << "Full Days: #{full_days.map {|d| d.to_date}.join(', ')}\n" if full_days.present?
     	message << "Half Days: #{half_days.map {|d| d.to_date}.join(', ')}" if half_days.present?
     	self.errors.add(:base, message)
      end
    end
  end
  
  def check_public_holidays
    public_holidays = LmsYearlySetting.current_year_settings.lms_public_holidays.map(&:ph_date).sort
    ldo = self.leave_dates_object.collect {|date| date.to_date}
    app_pub_holidays = []
    public_holidays.each do |holiday|
      app_pub_holidays.push(holiday) if ldo.include? holiday
    end
    self.errors.add(:base, "Please remove the public holidays(#{app_pub_holidays.join(', ')})") if app_pub_holidays.present?
  end
  
  def validate_notificants
    notify_emails = self.notificants.split(',').map {|e| e.strip}.select {|e| e.present?}
    notify_emails.each do |email|
      next if email.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i)
      self.errors.add :base, 'Notifications email address is incorrect'
      break
    end
  end
  
  def self.fetch_leaves(status)
    condition = case status
	    when :pending
	      ["lms_leaves.user_id <> ? AND lms_leave_statuses.status = ? AND year = YEAR(NOW())", Employee.current.id, LmsLeaveStatus::PENDING]
	    when :approved
	      ["lms_leaves.user_id <> ? AND lms_leave_statuses.status = ? AND year = YEAR(NOW())", Employee.current.id, LmsLeaveStatus::APPROVED]
	    when :processed
	      ["lms_leaves.user_id <> ? AND lms_leave_statuses.status = ? AND year = YEAR(NOW())", Employee.current.id, LmsLeaveStatus::PROCESSED]
	    when :approved_and_processed
	      ["lms_leaves.user_id <> ? AND (lms_leave_statuses.status = ? OR lms_leave_statuses.status = ?) AND year = YEAR(NOW())", Employee.current.id, LmsLeaveStatus::APPROVED, LmsLeaveStatus::PROCESSED]
	    when :rejected
	      ["lms_leaves.user_id <> ? AND lms_leave_statuses.status = ? AND year = YEAR(NOW())", Employee.current.id, LmsLeaveStatus::REJECTED]
	    when :cancelled
	      ["lms_leaves.user_id <> ? AND lms_leave_statuses.status = ? AND year = YEAR(NOW())", Employee.current.id, LmsLeaveStatus::CANCELLED]
	end
    self.find(:all, :joins => [:employee, :lms_leave_status, :lms_yearly_leave_history => :lms_yearly_setting], 
			:conditions => condition, 
			:select => "CONCAT(users.firstname, ' ', users.lastname) AS emp_name, lms_leaves.id AS id, #{LmsLeave.select_column_names_excluding_id}, lms_leave_statuses.id AS lms_leave_status_id, #{LmsLeaveStatus.select_column_names_excluding_id}", 
			:order => "status ASC, from_date ASC, to_date ASC")
  end
  
  def self.filter_leaves(leaves)
    unless LeaveManagementSystem.allowed_to? Employee.current, LeaveManagementSystem::ROLES[:dt]
      reportee_id = Employee.current.id.to_s
      leaves.select {|leave| leave.reported_to.include? reportee_id}
    else
      leaves
    end
  end
end