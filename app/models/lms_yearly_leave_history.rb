class LmsYearlyLeaveHistory < ActiveRecord::Base
  unloadable
  has_many :lms_monthly_leave_histories, :dependent => :destroy
  has_many :lms_leaves, :class_name => 'LmsLeave', :dependent => :destroy
  belongs_to :employee, :foreign_key => 'user_id'
  belongs_to :lms_yearly_setting
  
  attr_accessor :month_start
  scope :years, select("year").uniq
  validate :leave_account, :on => :update
  after_create :generate_monthly_leave_histories
  after_update :update_total_leaves
  
  def self.generate_yearly_leave_history
    lms_leave_setting = LmsLeaveSetting.first
    cur_year = Date.today.year
    prev_year = cur_year - 1
    lms_yearly_setting = LmsYearlySetting.create :year => cur_year, :carry_forward => lms_leave_setting.will_be_carry_forwarded, :carry_forward_limit => lms_leave_setting.will_be_carry_forwarded ? lms_leave_setting.max_days : 0, :work_from_home => lms_leave_setting.work_from_home, :work_from_home_limit => lms_leave_setting.work_from_home ? lms_leave_setting.work_from_home_limit : 0
    employees = LeaveManagementSystem.active_employees_with_role LeaveManagementSystem::ROLES[:al]
    records = []
    employees.each do |e|
      next if e.current_year_leave_history
      prev_year_leave_history, carry_forward = nil, 0
      if lms_yearly_setting.carry_forward
        prev_year_leave_history = e.previous_year_leave_history
        carry_forward = prev_year_leave_history.available_leaves > lms_yearly_setting.carry_forward_limit ? lms_yearly_setting.carry_forward_limit : prev_year_leave_history.available_leaves
      end
      wfh = lms_yearly_setting.work_from_home ? lms_yearly_setting.work_from_home_limit : 0
      records << {:user_id => e.id, :lms_yearly_setting_id => lms_yearly_setting.id, :tot_carry_forward => carry_forward, :total_leaves => carry_forward, :tot_wfh => wfh}
    end
    LmsYearlyLeaveHistory.create records
  end

  def self.update_total_leaves(yearly_settings)
    active_leave_types = yearly_settings.leave_types
    fields = active_leave_types.present? ? active_leave_types.joins(:lms_custom_fields).select('lms_custom_fields.column_name').where('lms_custom_fields.table_name' => 'lms_yearly_leave_histories').map(&:column_name) : []
    fields << 'tot_carry_forward' if yearly_settings.carry_forward
    raw_sql = "UPDATE lms_yearly_leave_histories SET total_leaves = #{fields.present? ? fields.join('+') : 0} WHERE lms_yearly_setting_id = #{yearly_settings.id};"
    ActiveRecord::Base.connection.execute(raw_sql)
    ActiveRecord::Base.connection.close
  end
    
  private
  
  def leave_account
    yearly_settings = LmsYearlySetting.current_year_settings
    leave_types = yearly_settings.leave_types
    leave_history = self.employee.leave_history leave_types.map(&:identifier), yearly_settings.year, 12
    if yearly_settings.carry_forward
      if self.tot_carry_forward > yearly_settings.carry_forward_limit
        self.errors.add(:base, "Carry forward should not cross #{yearly_settings.carry_forward_limit} day(s)")
      elsif self.tot_carry_forward < 0
	self.errors.add(:base, "Carry forward should not be less than 0 days")
      elsif self.tot_carry_forward < leave_history.ded_carry_forward
        self.errors.add(:base, "Has used #{leave_history.ded_carry_forward} carry forward leaves already")
      end
    end
    
    leave_types.each do |lt|
      if self.send("tot_#{lt.identifier}") > yearly_settings.send("tot_#{lt.identifier}")
	self.errors.add(:base, "#{lt.name} should not cross #{yearly_settings.send 'tot_' + lt.identifier} day(s)")
      elsif self.send("tot_#{lt.identifier}") < 0
	self.errors.add(:base, "#{lt.name} should not be less than 0 days")
      elsif self.send("tot_#{lt.identifier}") < leave_history.send("ded_#{lt.identifier}")
        self.errors.add(:base, "Has used #{leave_history.send("ded_#{lt.identifier}")} #{lt.name.downcase} already")
      end
    end
    
    if yearly_settings.work_from_home
      if self.tot_wfh > yearly_settings.work_from_home_limit
	self.errors.add(:base, "Work from home should not cross #{yearly_settings.work_from_home_limit} day(s)")
      elsif self.tot_wfh < 0
	self.errors.add(:base, "Work from home should not be less than 0 days")
      end
    end
  end

  def generate_monthly_leave_histories
    records, uid, yid, m_start = [], self.user_id, self.id, self.month_start || 1
    m_start.upto(12) {|month| records << {:user_id => uid, :lms_yearly_leave_history_id => yid, :month => month}}
    LmsMonthlyLeaveHistory.create records
  end
  
  def update_total_leaves
    yearly_settings = LmsYearlySetting.current_year_settings
    active_leave_types = yearly_settings.leave_types
    fields = active_leave_types.map(&:identifier).map {|f| "tot_" + f}
    fields << "tot_carry_forward" if yearly_settings.carry_forward
    fields.each do |field|
      if self.send "#{field}_changed?"
	#self.update_attributes :total_leaves => fields.inject(0) {|tot, f| tot + self.send(f)}
	raw_sql = "UPDATE #{self.class.table_name} SET total_leaves = #{fields.present? ? fields.join('+') : 0} WHERE id = #{self.id};"
	ActiveRecord::Base.connection.execute(raw_sql)
	return true
      end
    end
  end
end
