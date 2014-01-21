require 'leave_management_system'
Redmine::Plugin.register :leave_management_system do
  name 'Leave Management System plugin'
  author 'Johnson'
  description 'Leave Management System plugin'
  version '0.0.1'
  url 'https://github.com/johnson-johnson/leave_management_system'
  author_url 'http://www.linkedin.com/in/johnsonjoney'

  #requires_redmine :version_or_higher => '2.1.0'
  #requires_redmine_plugin :redmine_people, :version_or_higher => '0.1.0'
  
  settings :partial => 'settings/leave_management_system',
    :default => {
    :config => {:groups => {:appliers => [], :approvers => [], :deductors => []}}
  }

   menu :admin_menu, :leave_management_system, { :controller => 'settings', 
    :action => 'plugin', :id => :leave_management_system }, :caption => 'Leave Management System'
   menu :top_menu, :lms_dashboards, { :controller => 'lms_dashboards', :action => 'index' }, :caption => 'LMS', :if => Proc.new { LeaveManagementSystem.allowed_to?(User.current, LeaveManagementSystem::ROLES[:al]) || LeaveManagementSystem.allowed_to?(User.current, LeaveManagementSystem::ROLES[:ar]) || LeaveManagementSystem.allowed_to?(User.current, LeaveManagementSystem::ROLES[:dt]) || LeaveManagementSystem.allowed_to?(User.current, LeaveManagementSystem::ROLES[:rt]) }
end
