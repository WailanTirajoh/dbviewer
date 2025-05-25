class Position < ApplicationRecord
  belongs_to :department
  has_many :employees, dependent: :destroy

  validates :title, presence: true
  validates :min_salary, :max_salary, numericality: { greater_than: 0 }, allow_nil: true
  validate :max_salary_greater_than_min_salary

  private

  def max_salary_greater_than_min_salary
    return unless min_salary && max_salary

    errors.add(:max_salary, "must be greater than minimum salary") if max_salary <= min_salary
  end
end
