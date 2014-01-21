class LmsPublicHolidaysController < ApplicationController
  unloadable
  include LeaveManagementSystem::Controller

  before_filter :lms_authorize
  before_filter :find_current_year_settings
  before_filter :find_public_holiday, :only => [:edit, :update, :destroy]
  
  def index
    find_public_holidays
    respond_to do |format|
      format.js
    end
  end
  
  def new
    @public_holiday = @yearly_settings.lms_public_holidays.build
    respond_to do |format|
      format.js
    end
  end
  
  def create
    @public_holiday = @yearly_settings.lms_public_holidays.build params[:lms_public_holiday]
    unless @public_holiday.save
      respond_to do |format|
        format.js {render :action => :new}
      end  
    else
      find_public_holidays
      respond_to do |format|
        format.js
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
    unless @public_holiday.update_attributes params[:lms_public_holiday]
      respond_to do |format|
        format.js {render :action => :edit}
      end  
    else
      find_public_holidays
      respond_to do |format|
        format.js
      end
    end
  end
  
  def destroy
    @public_holiday.destroy if @public_holiday
    find_public_holidays
    respond_to do |format|
      format.js
    end
  end
  
  private
  def find_public_holiday
    @public_holiday = LmsPublicHoliday.find :first, :conditions => ["id = ?", params[:id]]
  end
end
