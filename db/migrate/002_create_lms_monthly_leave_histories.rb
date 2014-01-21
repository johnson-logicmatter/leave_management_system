class CreateLmsMonthlyLeaveHistories < ActiveRecord::Migration
  def change
    create_table :lms_monthly_leave_histories do |t|
      t.integer :user_id
      t.integer :lms_yearly_leave_history_id
      t.integer :month
      t.decimal :ded_carry_forward, :precision => 7, :scale => 2, :default => 0
      t.decimal :lop, :precision => 7, :scale => 2, :default => 0
      t.decimal :total_leaves_taken, :precision => 7, :scale => 2, :default => 0
      t.decimal :ded_wfh, :precision => 7, :scale => 2, :default => 0
      t.timestamps
    end
    add_index :lms_monthly_leave_histories, :user_id
    add_index :lms_monthly_leave_histories, :lms_yearly_leave_history_id
  end
end
