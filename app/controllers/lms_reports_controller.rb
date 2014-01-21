class LmsReportsController < ApplicationController
  unloadable
  include LeaveManagementSystem::Controller

  before_filter :lms_authorize
  before_filter :find_leave_settings_and_leave_types, :except => [:index]
  before_filter :find_employees_leave_histories, :only => [:month, :year, :ytd]
  before_filter :find_employee_leaves, :only => [:month_detailed, :year_detailed, :ytd_detailed]
  
  def index

  end
  
  def month

  end
  
  def year

  end
  
  def ytd

  end
  
  def month_detailed
    respond_to do |format|
      format.js
    end
  end
  
  def year_detailed
    respond_to do |format|
      format.js
    end 
  end
  
  def ytd_detailed
    respond_to do |format|
      format.js
    end
  end
  
  private
  def find_leave_settings_and_leave_types
    @years = LmsYearlySetting.order("year DESC").map(&:year)
    if @years.present?
      @year = (params[:year] || Date.today.year).to_i
      @year = @years.include?(@year) ? @year : @years.first
      unless ['year', 'year_detailed'].include? action_name
        @month = params[:month] || Date.today.month
      else
        @month = 12
      end
      @yearly_settings = LmsYearlySetting.find :first, :conditions => ["year = ?", @year]
      find_leave_types
    else
      render :action => :no_data
    end
  end
  
  def find_employee_leaves
    begin
      @employee = Employee.find params[:user_id]
      r_period = case action_name
	  when :month_detailed
	        LmsLeaveType::MONTH
	  else
	       LmsLeaveType::YEAR
	  end
      @leaves = @employee.leaves(@year, @month, LmsLeaveStatus::PROCESSED, r_period, LmsLeave::LEAVE)
      @wfh = @employee.leaves(@year, @month, LmsLeaveStatus::PROCESSED, r_period, LmsLeave::WFH) 
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
  
  def find_employees_leave_histories
    @employees = LeaveManagementSystem.employees_with_role LeaveManagementSystem::ROLES[:al]
    @leave_histories = []
    r_period = case action_name
	when :month
	      LmsLeaveType::MONTH
	else
	     LmsLeaveType::YEAR
	end
    @employees.each do|u|
      leave_history = u.leave_history(@active_leave_types.map(&:identifier), @year, @month, r_period)
      next unless leave_history
      @leave_histories << leave_history
    end
  end
end
