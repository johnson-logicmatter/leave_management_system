namespace :redmine do
  namespace :lms do
    desc 'Generate Yearly Leave History for all employees'
    task :generate_yearly_leave_history => :environment do
      LmsYearlyLeaveHistory.generate_yearly_leave_history
    end

    desc 'Clear all tables'
    task :clear_tables => :environment do
      ActiveRecord::Base.connection.execute "TRUNCATE lms_custom_fields;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_leave_categories;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_yearly_settings;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_leave_statuses;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_leave_types;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_leave_types_lms_yearly_settings;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_leaves;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_monthly_leave_histories;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_public_holidays;"
      ActiveRecord::Base.connection.execute "TRUNCATE lms_yearly_leave_histories;"
    end
  end
end