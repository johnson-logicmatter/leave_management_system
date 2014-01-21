Rails.configuration.to_prepare do  

  #require_dependency 'leave_management_system/patches/*_helper_patch'
  require_dependency 'leave_management_system/patches/active_record_base_patch'
  require_dependency 'leave_management_system/patches/mailer_patch'
  require_dependency 'leave_management_system/patches/user_patch'
  require_dependency 'leave_management_system/patches/application_helper_patch'
  require_dependency 'leave_management_system/hooks/views_layouts_hook'
end

module LeaveManagementSystem
  ROLES = {:al => 'appliers', :ar => 'approvers', :dt => 'deductors', :rt => 'reporters'}
  def self.settings() Setting[:plugin_leave_management_system] end
  
  def self.allowed_to?(obj, role)
    if obj.is_a? User
      self.user_has_role?(obj, role)
    else
      return false
    end
  end
  
  def self.user_has_role?(user, role)
    self.employees_with_role(role).map(&:id).include? user.id
  end
  
  def self.allocated_groups(role)
    settings = self.settings
    settings['config'] ? settings['config']['groups'][role] || [] : []
  end

  def self.employees_with_role(role)
    Employee.find(:all, :joins => :groups, :conditions => ["group_id IN (?)", self.allocated_groups(role)], :order => "firstname ASC")
  end
  
  def self.active_employees_with_role(role)
    Employee.find(:all, :joins => :groups, :conditions => ["group_id IN (?) AND #{Employee.table_name}.status = ?", self.allocated_groups(role), User::STATUS_ACTIVE], :order => "firstname ASC")
  end
  
  module Controller
    private
    def lms_authorize
      user = User.current
      authorized = case controller_name
	when 'lms_dashboards'
          LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:al]) || LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:ar]) || LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:dt]) || LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:rt])
	when 'lms_settings', 'lms_leave_accounts'
	  LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:dt])
	when 'lms_public_holidays'
	  if action_name == 'index'
	    LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:al]) || LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:ar]) || LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:dt]) || LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:rt])
	  else
	    LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:dt])
	  end
	when 'lms_reports'
	  LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:dt]) || LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:rt])
	when 'lms_leave_types'
	  LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:dt])
	when 'lms_leaves'
	  compare_action(user)
	end
      if authorized
	@employee = user.becomes Employee
        return true
      else
        deny_access
      end
    end
    
    def compare_action(user)
      case action_name
        when 'new', 'create', 'destroy'
          LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:al])
        when 'approve', 'reject'
          LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:ar])
        when 'proces', 'deduct'
          LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:dt])
        when 'pending', 'approved', 'rejected', 'cancelled'
          if params[:menu] == 'Others'
             LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:ar]) || LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:dt])
          else
            LeaveManagementSystem.allowed_to?(user, LeaveManagementSystem::ROLES[:al])
          end
      end
    end

    def find_current_year_settings
      @yearly_settings = LmsYearlySetting.current_year_settings
    end
    
    def find_leave_types
      @leave_types = LmsLeaveType.find(:all)
      @active_leave_types = @yearly_settings ? @yearly_settings.leave_types : []
    end
    
    def find_public_holidays
      @public_holidays = @yearly_settings ? @yearly_settings.lms_public_holidays.order("ph_date ASC") : []
    end
  end
  
end
