class CreateLmsLeaves < ActiveRecord::Migration
  def change
    create_table :lms_leaves do |t|
      t.integer :user_id
      t.integer :lms_yearly_leave_history_id
      t.integer :lms_monthly_leave_history_id
      t.date :from_date
      t.date :to_date
      t.decimal :no_of_days, :precision => 7, :scale => 2, :default => 0
      t.binary :leave_dates_object
      t.text :reason
      t.binary :reported_to
      t.text :notificants
      t.integer :leave_category_id
      t.integer :parent_leave_id
      t.timestamps
    end
    add_index :lms_leaves, :user_id
    add_index :lms_leaves, :lms_yearly_leave_history_id
    add_index :lms_leaves, :lms_monthly_leave_history_id
  end
end
