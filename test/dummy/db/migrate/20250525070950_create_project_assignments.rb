class CreateProjectAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :project_assignments do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :role
      t.date :assigned_date
      t.decimal :hours_per_week

      t.timestamps
    end
  end
end
