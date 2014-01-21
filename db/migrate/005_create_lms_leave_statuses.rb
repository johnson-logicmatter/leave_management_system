class CreateLmsLeaveStatuses < ActiveRecord::Migration
  def change
    create_table :lms_leave_statuses do |t|
      t.integer :lms_leave_id
      t.integer :status, :default => 0
      t.decimal :lop, :precision => 7, :scale => 2, :default => 0
      t.decimal :ded_carry_forward, :precision => 7, :scale => 2, :default => 0
      t.decimal :ded_wfh, :precision => 7, :scale => 2, :default => 0
      t.integer :approved_by
      t.date :approved_on
      t.integer :processed_by
      t.date :processed_on
      t.integer :rejected_by
      t.date :rejected_on
      t.date :cancelled_on
      t.timestamps
    end
  end
end
