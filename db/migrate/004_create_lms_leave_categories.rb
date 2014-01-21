class CreateLmsLeaveCategories < ActiveRecord::Migration
  def change
    create_table :lms_leave_categories do |t|
      t.string :name
      t.timestamps
    end
  end
end
