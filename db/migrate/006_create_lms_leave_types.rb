class CreateLmsLeaveTypes < ActiveRecord::Migration
  def change
    create_table :lms_leave_types do |t|
      t.string :name
      t.integer :days, :default => 0
      t.string :identifier, :unique => true
      t.integer :period
      t.boolean :accountable, :default => true
      t.timestamps
    end
  end
end
