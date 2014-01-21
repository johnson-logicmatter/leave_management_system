module LmsSettingsHelper
  include LmsLeaveTypesHelper
  
  def start_present_year_leave_tracking
    yearly_settings = LmsYearlySetting.current_year_settings
    if !yearly_settings
      link_to 'Generate Leave Accounts', generate_leave_history_lms_settings_path, :title => "Click here to generate this year leave accounts for all employees."
    elsif !yearly_settings.started?
      link_to 'Start Tracking', start_lms_setting_path(yearly_settings), :title => "Click here to start the system to allow the employees to apply leaves. Before start the system, activate the needed leave types and common settings for this year.", :confirm => "Are every settings configured needed for this year? Once you started the system, no settings can be modified."
    else
      link_to "Manage Leave Accounts", lms_leave_accounts_path
    end
  end
  
  def groups(role)
    Group.find(:all, :conditions => ["id in (?)", LeaveManagementSystem.allocated_groups(role)]).map(&:name).join(', ')
  end
end
