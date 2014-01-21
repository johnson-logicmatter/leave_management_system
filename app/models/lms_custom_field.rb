class LmsCustomField < ActiveRecord::Base
  unloadable
  belongs_to :lms_leave_type
end
