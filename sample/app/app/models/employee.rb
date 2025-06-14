class Employee < ApplicationRecord
  belongs_to :company
  belongs_to :department
  belongs_to :position
  has_many :project_assignments, dependent: :destroy
  has_many :projects, through: :project_assignments
  has_many :employee_skills, dependent: :destroy
  has_many :skills, through: :employee_skills

  validates :first_name, :last_name, :email, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :salary, numericality: { greater_than: 0 }, allow_nil: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
