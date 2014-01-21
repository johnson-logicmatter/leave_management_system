class CreateLmsLeaveSettings < ActiveRecord::Migration
  def change
    create_table :lms_leave_settings do |t|
      t.boolean :will_be_carry_forwarded
      t.boolean :will_be_cash_backed
      t.integer :max_days, :default => 0
      t.boolean :work_from_home, :default => false
      t.integer :work_from_home_limit, :default => 1
      t.string :weekends, :default => "0"
      t.timestamps
    end
    LmsLeaveSetting.create(:will_be_carry_forwarded => true, :will_be_cash_backed => false, :max_days => 4)
  end
end
