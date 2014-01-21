class LmsPublicHoliday < ActiveRecord::Base
  unloadable
  belongs_to :lms_yearly_setting
  
  validates_presence_of :occ_name, :ph_date
  validates_uniqueness_of :ph_date
end
