class EmployeeSkill < ApplicationRecord
  belongs_to :employee
  belongs_to :skill

  validates :proficiency_level, presence: true
  validates :proficiency_level, inclusion: { in: 1..5 }
  validates :years_experience, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
