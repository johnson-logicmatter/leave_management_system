class LmsLeaveCategory < ActiveRecord::Base
  unloadable
  belongs_to :lms_leave
  
  LEAVE_CATEGORIES = {1 => "Planned Leave", 2 => "Sick Leave"}
  WORK_FROM_HOME = {3 => "Work From Home"}
  
  def self.all
    LEAVE_CATEGORIES.merge WORK_FROM_HOME
  end
end
