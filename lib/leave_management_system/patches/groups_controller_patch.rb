module LeaveManagementSystem
  module Patches
    module GroupsController
      def self.included base
        base.class_eval do
	  include InstanceMethods
	  after_filter :group_model_callback, :only => [:add_users]
	  private :group_model_callback
	end
      end
      
      module InstanceMethods
        def group_model_callback
	  User.create_leave_accounts(@users) if request.post? && @group.leave_appliers?
	end
      end
    end
  end
end

unless GroupsController.included_modules.include? LeaveManagementSystem::Patches::GroupsController
  GroupsController.send :include, LeaveManagementSystem::Patches::GroupsController
end