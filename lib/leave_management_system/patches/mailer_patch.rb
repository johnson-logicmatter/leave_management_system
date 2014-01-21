module LeaveManagementSystem
  module Patches
    module MailerPatch
      def self.included base
        base.class_eval do
	  unloadable
	  include InstanceMethods
	end
      end
      module InstanceMethods
        def apply_leave(leave)
	  @leave = leave
	  @leave_type = LmsLeaveCategory::WORK_FROM_HOME[@leave.leave_category_id] ? "Work from home" : "Leave"
	  @applier = @leave.employee
	  @approvers = Employee.find @leave.reported_to
	  mail :to => @approvers.map(&:mail), :subject => "LMS : [ #{@applier.name} - #{@leave.id} ] Apply #{@leave_type}", :html => true
	end
        
	def approve_leave(leave)
	  @leave = leave
	  @leave_type = LmsLeaveCategory::WORK_FROM_HOME[@leave.leave_category_id] ? "Work from home" : "Leave"
	  @applier = @leave.employee
	  @approver = @leave.approver
	  receipents = LeaveManagementSystem.active_employees_with_role LeaveManagementSystem::ROLES[:dt]
	  mail :to => receipents.map(&:mail), :subject => "LMS : [ #{@applier.name} - #{@leave.id} ] Apply #{@leave_type}", :html => true
	end
	
	def approve_leave_notification(leave)
	  @leave = leave
	  @leave_type = LmsLeaveCategory::WORK_FROM_HOME[@leave.leave_category_id] ? "Work from home" : "Leave"
	  @applier = @leave.employee
	  @approver = @leave.approver
	  mail :to => @applier.mail, :subject => "LMS : [ #{@applier.name} - #{@leave.id} ] Apply #{@leave_type}", :html => true
	end
        
	def notify_team(leave)
	  @leave = leave
	  @leave_type = LmsLeaveCategory::WORK_FROM_HOME[@leave.leave_category_id] ? "Work from home" : "Leave"
	  @applier = @leave.employee
	  @message = LmsLeaveCategory::WORK_FROM_HOME[@leave.leave_category_id] ? "will be working from home on following date(s)" : "will be in leave on following date(s)"
	  receipents = @leave.notificants.split(',').map {|email| email.strip}.select {|email| email.present?}.uniq
	  mail :to => receipents, :subject => "LMS : [#{@applier.name} - #{@leave.id}] #{@leave_type} approved", :html => true
	end
	
	def reject_leave_notification(leave)
	  @leave = leave
	  @leave_type = LmsLeaveCategory::WORK_FROM_HOME[@leave.leave_category_id] ? "Work from home" : "Leave"
	  @applier = @leave.employee
	  @rejector = @leave.rejector
	  mail :to => @applier.mail, :subject => "LMS : [ #{@applier.name} - #{@leave.id} ] Apply #{@leave_type}", :html => true
	end

	def process_leave_notification(leave)
	  @leave = leave
	  @leave_type = LmsLeaveCategory::WORK_FROM_HOME[@leave.leave_category_id] ? "Work from home" : "Leave"
	  @applier = @leave.employee
	  @processor = @leave.processor
	  mail :to => @applier.mail, :subject => "LMS : [ #{@applier.name} - #{@leave.id} ] Apply #{@leave_type}", :html => true
	end
        
      end
    end
  end
end

unless Mailer.included_modules.include? LeaveManagementSystem::Patches::MailerPatch
  Mailer.send :include, LeaveManagementSystem::Patches::MailerPatch
end