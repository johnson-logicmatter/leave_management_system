class CreateLmsYearlySettings < ActiveRecord::Migration
  def change
    create_table :lms_yearly_settings do |t|
      t.integer :year
      t.boolean :carry_forward, :default => false
      t.integer :carry_forward_limit
      t.boolean :work_from_home, :default => false
      t.integer :work_from_home_limit
      t.boolean :started, :default => false
      t.timestamps
    end
    create_table :lms_leave_types_lms_yearly_settings, :id => false do |t|
      t.integer :lms_yearly_setting_id
      t.integer :lms_leave_type_id
    end
    add_index :lms_leave_types_lms_yearly_settings, [:lms_yearly_setting_id, :lms_leave_type_id], :name => 'index_yearly_settings_leave_types'
  end
end
