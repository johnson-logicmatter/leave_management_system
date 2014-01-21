class LmsDashboardsController < ApplicationController
  unloadable
  include LeaveManagementSystem::Controller

  before_filter :lms_authorize
  before_filter :find_current_year_settings
  before_filter :find_leave_types
  
  def index
    if params[:menu] && params[:menu] == 'Others'
      if params[:tab] == 'pending'
        @leaves = LmsLeave.pending_leaves
      elsif params[:tab] == 'approved'
        @leaves = LmsLeave.approved_and_processed_leaves
      end
    else
      @leaves = Employee.pending_leaves
    end
    @leave_summary = @yearly_settings ? @employee.leave_history(@active_leave_types.map(&:identifier), Date.today.year, 12) : nil
    @present_month_leave_histories = @yearly_settings ? @employee.leave_history(@active_leave_types.map(&:identifier), Date.today.year, Date.today.month, LmsLeaveType::MONTH) : nil
  end
end
