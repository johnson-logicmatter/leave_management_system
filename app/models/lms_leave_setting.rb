class LmsLeaveSetting < ActiveRecord::Base
  unloadable
  WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  validates_numericality_of :max_days, :work_from_home_limit, :only_integer => true, :greater_than => 0
  after_save :update_present_year_leave_settings
   
  private
  def update_present_year_leave_settings
    yearly_settings = LmsYearlySetting.current_year_settings
    if yearly_settings
      if max_days_changed? ||  (will_be_carry_forwarded_changed? && will_be_carry_forwarded)
	yearly_settings.update_carry_forward(self)
      elsif !max_days_changed? && will_be_carry_forwarded_changed? && !will_be_carry_forwarded
        yearly_settings.clear_carry_forward
      end

      if work_from_home_limit_changed? || (work_from_home_changed? && work_from_home)
        yearly_settings.update_work_from_home(self)
      elsif !work_from_home_limit_changed? && work_from_home_changed? && !work_from_home
        yearly_settings.clear_work_from_home
      end
    end
  end
end
