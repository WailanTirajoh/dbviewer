class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.references :company, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.references :position, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone
      t.date :hire_date
      t.decimal :salary

      t.timestamps
    end
    add_index :employees, :email, unique: true
  end
end
