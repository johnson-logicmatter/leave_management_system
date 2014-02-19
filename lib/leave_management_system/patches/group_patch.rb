module LeaveManagementSystem
  module Patches
    module Group
      def self.included base
        base.class_eval do
	  include InstanceMethods
	end
      end
      
      module InstanceMethods
        def leave_appliers?
	  LeaveManagementSystem.allocated_groups(LeaveManagementSystem::ROLES[:al]).include? self.id.to_s
	end
      end
    end
  end
end

unless Group.included_modules.include? LeaveManagementSystem::Patches::Group
  Group.send :include, LeaveManagementSystem::Patches::Group
end