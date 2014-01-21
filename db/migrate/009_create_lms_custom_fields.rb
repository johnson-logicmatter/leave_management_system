class CreateLmsCustomFields < ActiveRecord::Migration
  def change
    create_table :lms_custom_fields do |t|
      t.integer :lms_leave_type_id
      t.string :table_name
      t.string :column_name
      t.timestamps
    end
    add_index :lms_custom_fields, :lms_leave_type_id
  end
end
