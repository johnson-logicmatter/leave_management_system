class LmsSettingsController < ApplicationController
  unloadable
  include LeaveManagementSystem::Controller

  before_filter :lms_authorize
  before_filter :find_current_year_settings, :only => [:index]
  before_filter :find_leave_types, :only => [:index]
  before_filter :find_public_holidays, :only => [:index]
  
  def index
    @leave_setting = LmsLeaveSetting.find(:first)
  end
  
  def update
    @leave_setting = LmsLeaveSetting.find_by_id params[:id]
    if params[:lms_leave_setting]
      params[:lms_leave_setting][:weekends] = params[:lms_leave_setting][:weekends].present? ? params[:lms_leave_setting][:weekends].join(',') : ""
    else
      params[:lms_leave_setting] = {:weekends => ""}
    end
    @leave_setting.update_attributes params[:lms_leave_setting]
    redirect_to :action => :index
  end
  
  def generate_leave_history
    LmsYearlyLeaveHistory.generate_yearly_leave_history
    redirect_to :action => :index
  end
  
  def start
    @present_year_settings = LmsYearlySetting.find params[:id]
    @present_year_settings.update_attribute :started, true
    redirect_to :action => :index
  end
end
