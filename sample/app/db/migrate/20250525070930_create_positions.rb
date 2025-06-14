class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.references :department, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.decimal :min_salary
      t.decimal :max_salary

      t.timestamps
    end
  end
end
