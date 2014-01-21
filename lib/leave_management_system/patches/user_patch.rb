require_dependency 'project'

module LeaveManagementSystem
  module Patches
    module UserPatch
      def self.included base
        base.class_eval do
	  unloadable
	  include InstanceMethods
	  after_save :create_leave_account
	  private :create_leave_account
	end
      end
      
      module InstanceMethods
        def create_leave_account
	  yearly_settings = LmsYearlySetting.current_year_settings
	  employee = self.becomes Employee
	  if LeaveManagementSystem.user_has_role?(self, LeaveManagementSystem::ROLES[:al]) && yearly_settings && !employee.current_year_leave_history
	    fields = {:lms_yearly_setting_id => yearly_settings.id, :tot_carry_forward => 0, :total_leaves => 0}
	    leave_types = yearly_settings.leave_types
	    leave_types.each do |lt|
	      fields.merge! "tot_#{lt.identifier}".to_sym => yearly_settings.send("tot_#{lt.identifier}")
	      fields[:total_leaves] += yearly_settings.send("tot_#{lt.identifier}")
	    end
	    fields.merge!(:tot_wfh => yearly_settings.work_from_home_limit) if yearly_settings.work_from_home
	    employee.lms_yearly_leave_histories.create fields
	  end
	end
      end
    end
  end
end

unless User.included_modules.include? LeaveManagementSystem::Patches::UserPatch
  User.send :include, LeaveManagementSystem::Patches::UserPatch
end