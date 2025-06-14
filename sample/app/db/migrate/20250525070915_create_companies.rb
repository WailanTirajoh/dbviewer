class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.text :description
      t.string :website
      t.string :phone
      t.string :email
      t.date :founded_date
      t.integer :employee_count

      t.timestamps
    end
  end
end
