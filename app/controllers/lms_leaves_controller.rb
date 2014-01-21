class LmsLeavesController < ApplicationController
  unloadable
    include LeaveManagementSystem::Controller

  before_filter :lms_authorize
  before_filter :find_common_settings, :only => [:new, :create]
  before_filter :find_current_month_leave_history, :only => [:new, :create]
  before_filter :find_current_year_leave_history, :only => [:new, :create]
  before_filter :find_current_year_settings, :only => [:new, :create, :proces, :deduct]
  before_filter :find_leave_types, :only => [:proces, :deduct]
  before_filter :find_public_holidays, :only => [:new, :create]
  
  def new
    @leave = LmsLeave.new
    respond_to do |format|
      format.js
    end
  end

  def create
    @leave = @employee.lms_leaves.build :lms_yearly_leave_history_id => @current_month_leave_history.lms_yearly_leave_history_id, :lms_monthly_leave_history_id => @current_month_leave_history.id
    @leave.safe_attributes = params[:lms_leave]
    if @leave.valid?
      monthly_history = LmsMonthlyLeaveHistory.find(:first, :conditions => {:user_id => @current_month_leave_history.user_id, :lms_yearly_leave_history_id => @current_month_leave_history.lms_yearly_leave_history_id, :month => params[:lms_leave][:from_date].to_date.month})
      unless monthly_history
        @leave.errors.add :base, "You can't apply leave in this month"
	respond_to do |format|
          format.js {render :action => :new}
        end && return
      else
        @leave.lms_monthly_leave_history_id = monthly_history.id
      end
    end
    if @leave.save
      @pending_leaves = Employee.pending_leaves
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js {render :action => :new}
      end
    end
  end

  def edit
  end

  def update
  end

  def destroy
    leave = LmsLeave.find_by_id params[:id]
    leave_status = leave.lms_leave_status
    if leave_status.pending?
      leave_status.update_attributes :status => LmsLeaveStatus::CANCELLED, :cancelled_on => Time.now
    end
    @pending_leaves = Employee.pending_leaves
    respond_to do |format|
      format.js
    end
  end

  def approve
    leave = LmsLeave.find_by_id params[:id]
    leave_status = leave.lms_leave_status
    if leave_status.pending?
      leave_status.update_attributes :status => LmsLeaveStatus::APPROVED, :approved_by => @employee.id, :approved_on => Time.now
    end
    @pending_leaves = LmsLeave.pending_leaves
    params[:menu] = 'Others'
    respond_to do |format|
      format.html {redirect_to :controller => :lms_dashboards, :action => :index, :menu => params[:menu], :tab => 'pending'}
      format.js {}
    end  
  end

  def reject
    leave = LmsLeave.find_by_id params[:id]
    leave_status = leave.lms_leave_status
    if leave_status.pending?
      leave_status.update_attributes :status => LmsLeaveStatus::REJECTED, :rejected_by => @employee.id, :rejected_on => Time.now
    end
    @pending_leaves = LmsLeave.pending_leaves
    params[:menu] = 'Others'
    respond_to do |format|
      format.html {redirect_to :controller => :lms_dashboards, :action => :index, :menu => params[:menu], :tab => 'pending'}
      format.js
    end  
  end
  
  def proces
    unless request.xhr?
      redirect_to :controller => :lms_dashboards, :action => :index, :menu => 'Others', :tab => 'approved', :id => params[:id]
    else
      @leave = LmsLeave.find_by_id params[:id]
      @applier = @leave.employee
      @leave_history = @applier.leave_history(@active_leave_types.map(&:identifier), Date.today.year, 12) unless LmsLeaveCategory::WORK_FROM_HOME[@leave.leave_category_id]
      respond_to do |format|
        format.js
      end
    end
  end
  
  def deduct
    leave = LmsLeave.find_by_id params[:lms_leave_status][:lms_leave_id]
    if leave.lms_leave_status.approved?
      if LmsLeaveCategory::WORK_FROM_HOME[leave.leave_category_id]
        leave.lms_leave_status.update_attributes(:ded_wfh => leave.no_of_days, :status => LmsLeaveStatus::PROCESSED, :processed_by => @employee.id, :processed_on => Time.now)
      else
        unless leave.lms_leave_status.update_attributes(params[:lms_leave_status].merge(:status => LmsLeaveStatus::PROCESSED, :processed_by => @employee.id, :processed_on => Time.now))
	  @leave = leave
	  @applier = @leave.employee
	  @leave_history = @applier.leave_history(@active_leave_types.map(&:identifier), Date.today.year, 12)
          respond_to do |format|
            format.js {render :action => :proces}
          end && return
	end
      end
    end
    params[:menu] = params[:menu] || 'Others'
    if params[:menu] == 'Others'
      @approved_and_processed_leaves = LmsLeave.approved_and_processed_leaves
    else
      @approved_and_processed_leaves = Employee.approved_and_processed_leaves
    end
    respond_to do |format|
      format.js
    end
  end
  
  def index
  end
  
  def pending
    if params[:menu] == 'Others'
      @pending_leaves = LmsLeave.pending_leaves
    else
      @pending_leaves = Employee.pending_leaves
    end
    respond_to do |format|
      format.js
    end
  end
  
  def approved
    if params[:menu] == 'Others'
      @approved_and_processed_leaves = LmsLeave.approved_and_processed_leaves
    else
      @approved_and_processed_leaves = Employee.approved_and_processed_leaves
    end
    respond_to do |format|
      format.js
    end
  end

  def rejected
    if params[:menu] == 'Others'
      @rejected_leaves = LmsLeave.rejected_leaves
    else
      @rejected_leaves = Employee.rejected_leaves
    end
    respond_to do |format|
      format.js
    end
  end

  def cancelled
    if params[:menu] == 'Others'
      @cancelled_leaves = LmsLeave.cancelled_leaves
    else
      @cancelled_leaves = Employee.cancelled_leaves
    end
    respond_to do |format|
      format.js
    end
  end
  
  private
  def find_common_settings
    @lms_settings = LmsLeaveSetting.first
  end
   
  def find_current_month_leave_history
    @current_month_leave_history = @employee.current_month_leave_history
  end

  def find_current_year_leave_history
    @current_year_leave_history = @employee.current_year_leave_history
  end
end
