class LmsLeaveTypesController < ApplicationController
  unloadable
  include LeaveManagementSystem::Controller

  before_filter :lms_authorize
  before_filter :find_leave_type, :only => [:edit, :update, :activate, :deactivate, :destroy]
  before_filter :find_current_year_settings, :only => [:create, :update, :activate, :deactivate, :destroy]
  
  def new
    @leave_type = LmsLeaveType.new
    respond_to do |format|
      format.js
    end
  end

  def create
    @leave_type = LmsLeaveType.new
    @leave_type.safe_attributes = params[:lms_leave_type]
    if @leave_type.save
    find_leave_types
    respond_to do |format|
      format.js
    end
    else
    respond_to do |format|
      format.js {render :action => :new}
    end
    end
  end

  def show
  end

  def edit
    respond_to do |format|
      format.js
    end  
  end

  def update
    @leave_type.safe_attributes = params[:lms_leave_type]
    if @leave_type.save
    find_leave_types
    respond_to do |format|
      format.js
    end
    else
    respond_to do |format|
      format.js {render :action => :edit}
    end
    end
  end

  def activate
    if @leave_type && @yearly_settings
      @yearly_settings.leave_types << @leave_type
      @yearly_settings.update_leave_type @leave_type
    end
    find_leave_types
    respond_to do |format|
      format.js
    end
  end
  
  def deactivate
    if @leave_type && @yearly_settings
      @yearly_settings.leave_types = @yearly_settings.leave_types.find(:all, :conditions => ["lms_leave_type_id != ?", @leave_type.id])
      @yearly_settings.clear_leave_type @leave_type
    end
    find_leave_types
    respond_to do |format|
      format.js
    end
  end
  
  def destroy
    @leave_type.destroy
    find_leave_types
    respond_to do |format|
      format.js
    end
  end

  def index
    respond_to do |format|
      format.js
    end
  end
  
  private
  
  def find_leave_type
    @leave_type = LmsLeaveType.find_by_id(params[:id])
  end
end
