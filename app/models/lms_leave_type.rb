class LmsLeaveType < ActiveRecord::Base
  unloadable
  include Redmine::SafeAttributes
  
  #PERIODS = [[0,'Yearly'],[1, 'Quarterly'],[2, 'Monthly']]
  PERIODS = [[0,'Yearly']]
  YEAR = :y
  QUARTER = :q
  MONTH = :m
  IDENTIFIER_MAX_LENGTH = 20
  
  has_many :lms_custom_fields
  has_and_belongs_to_many :yearly_settings, :class_name => "LmsYearlySetting"
  
  validates_presence_of :name, :days, :period, :identifier
  validates_uniqueness_of :name, :identifier
  validates_length_of :name, :maximum => 40
  #validates_format_of :days, :with => /^[0-9]*\.?[0-9]+$/
  validates_numericality_of :days, :only_integer => true, :greater_than => 0
  validates_length_of :identifier, :in => 2..IDENTIFIER_MAX_LENGTH
  validates_format_of :identifier, :with => /^[a-z]+_*[a-z]+$/, :if => Proc.new { |t| t.identifier_changed? }
  
  safe_attributes 'name', 'days', 'period', 'accountable', 'identifier'
  
  after_create :create_custom_fields
  after_destroy :delete_custom_fields
  after_update :update_present_year_leave_history
  
  def identifier_frozen?
    errors[:identifier].blank? && !(new_record? || identifier.blank?)
  end
   
  private
  def create_custom_fields
    raw_sql = "ALTER TABLE #{LmsYearlySetting.table_name} ADD COLUMN tot_#{identifier} DECIMAL(7,2) DEFAULT 0;"
    ActiveRecord::Base.connection.execute(raw_sql)
    raw_sql = "ALTER TABLE #{LmsYearlyLeaveHistory.table_name} ADD COLUMN tot_#{identifier} DECIMAL(7,2) DEFAULT 0;"
    ActiveRecord::Base.connection.execute(raw_sql)
    raw_sql = "ALTER TABLE #{LmsMonthlyLeaveHistory.table_name} ADD COLUMN ded_#{identifier} DECIMAL(7,2) DEFAULT 0;"
    ActiveRecord::Base.connection.execute(raw_sql)
    raw_sql = "ALTER TABLE #{LmsLeaveStatus.table_name} ADD COLUMN ded_#{identifier} DECIMAL(7,2) DEFAULT 0;"
    ActiveRecord::Base.connection.execute(raw_sql)
    ActiveRecord::Base.connection.close
    lms_custom_fields.build({:table_name => LmsYearlySetting.table_name, :column_name => "tot_#{identifier}"}).save
    lms_custom_fields.build({:table_name => LmsYearlyLeaveHistory.table_name, :column_name => "tot_#{identifier}"}).save
    lms_custom_fields.build({:table_name => LmsMonthlyLeaveHistory.table_name, :column_name => "ded_#{identifier}"}).save
    lms_custom_fields.build({:table_name => LmsLeaveStatus.table_name, :column_name => "ded_#{identifier}"}).save
    reload_schema
  end
  
  def delete_custom_fields
    lms_custom_fields.each do |cf|
     raw_sql = "ALTER TABLE #{cf.table_name} DROP COLUMN #{cf.column_name};"
     ActiveRecord::Base.connection.execute(raw_sql)
     cf.destroy
    end
    ActiveRecord::Base.connection.close
    reload_schema
  end
    
  def update_present_year_leave_history
    if days_changed?
      year_settings = LmsYearlySetting.current_year_settings
      if year_settings
        if year_settings.leave_types.find :first, :conditions => ["lms_leave_type_id = ?", self.id]
           year_settings.update_leave_type self
	end
      end
    end
  end
  
  def reload_schema
    ["LmsYearlySetting", "LmsYearlyLeaveHistory", "LmsMonthlyLeaveHistory", "LmsLeaveStatus"].each {|class_name| Object.const_get(class_name).reset_column_information}
  end
end
