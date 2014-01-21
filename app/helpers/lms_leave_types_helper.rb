module LmsLeaveTypesHelper
  def is_activated_current_year?(leave_type)
    @active_leave_types.detect {|alt| alt == leave_type}
  end
  
  def was_activated_past_years?(leave_type)
    leave_type.yearly_settings.present?
  end
end
