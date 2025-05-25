class Company < ApplicationRecord
  has_many :departments, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :offices, dependent: :destroy

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :employee_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
