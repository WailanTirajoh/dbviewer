class CreateEmployeeSkills < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_skills do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.integer :proficiency_level
      t.integer :years_experience

      t.timestamps
    end
  end
end
