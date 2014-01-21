class LmsMonthlyLeaveHistory < ActiveRecord::Base
  unloadable
  has_many :lms_leaves, :class_name => 'LmsLeave', :dependent => :destroy
  belongs_to :lms_yearly_leave_history
  belongs_to :employee, :foreign_key => 'user_id'
end
