class CreateLmsYearlyLeaveHistories < ActiveRecord::Migration
  def change
    create_table :lms_yearly_leave_histories do |t|
      t.integer :user_id
      t.integer :lms_yearly_setting_id
      t.decimal :tot_carry_forward, :precision => 7, :scale => 2, :default => 0
      t.decimal :total_leaves, :precision => 7, :scale => 2, :default => 0
      t.decimal :tot_wfh, :precision => 7, :scale => 2, :default => 0
      t.timestamps
    end
    add_index :lms_yearly_leave_histories, :user_id
    add_index :lms_yearly_leave_histories, :lms_yearly_setting_id
  end
end
