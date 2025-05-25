class Department < ApplicationRecord
  belongs_to :company
  has_many :positions, dependent: :destroy
  has_many :employees, dependent: :destroy

  validates :name, presence: true
  validates :budget, numericality: { greater_than: 0 }, allow_nil: true
end
