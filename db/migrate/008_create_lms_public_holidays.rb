class CreateLmsPublicHolidays < ActiveRecord::Migration
  def change
    create_table :lms_public_holidays do |t|
      t.string :occ_name
      t.date :ph_date
      t.integer :lms_yearly_setting_id
      t.timestamps
    end
    add_index :lms_public_holidays, :lms_yearly_setting_id
  end
end
