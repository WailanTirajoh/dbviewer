class Skill < ApplicationRecord
  has_many :employee_skills, dependent: :destroy
  has_many :employees, through: :employee_skills

  validates :name, :category, presence: true
  validates :category, inclusion: { in: %w[technical soft leadership domain_specific] }
end
