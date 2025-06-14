class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.date :start_date
      t.date :end_date
      t.decimal :budget
      t.string :status

      t.timestamps
    end
  end
end
