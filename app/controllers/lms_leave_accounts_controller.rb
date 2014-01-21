class LmsLeaveAccountsController < ApplicationController
  unloadable
  include LeaveManagementSystem::Controller

  before_filter :lms_authorize
  before_filter :find_current_year_settings, :only => [:index]
  before_filter :find_leave_types, :only => [:index]

  def index
    @leave_accounts = LmsYearlyLeaveHistory.find :all, :joins => [:employee, :lms_yearly_setting], :conditions => ["year = YEAR(NOW())"], :select => "CONCAT(users.firstname, ' ', users.lastname) AS emp_name, #{LmsYearlyLeaveHistory.table_name}.*", :order => "emp_name ASC"
  end

  def create
  end

  def update
    yearly_leave_history = LmsYearlyLeaveHistory.find params[:id]
    status, data, error = 200, {}, []
    unless yearly_leave_history.update_attributes params[:leave_account]
      status = 406
      error = yearly_leave_history.errors.full_messages
    else
      params[:leave_account].each do |lt, days|
        data.merge! lt => yearly_leave_history.send(lt)
      end
    end
    render :json => {:status => status, :data => data, :error => error}
  end
end
