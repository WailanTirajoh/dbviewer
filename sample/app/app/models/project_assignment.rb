class ProjectAssignment < ApplicationRecord
  belongs_to :employee
  belongs_to :project

  validates :role, :assigned_date, presence: true
  validates :hours_per_week, numericality: { greater_than: 0, less_than_or_equal_to: 40 }, allow_nil: true
  validates :role, inclusion: { in: %w[lead developer designer tester analyst manager] }
end
