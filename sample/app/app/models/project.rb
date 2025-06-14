class Project < ApplicationRecord
  belongs_to :company
  has_many :project_assignments, dependent: :destroy
  has_many :employees, through: :project_assignments

  validates :name, :status, presence: true
  validates :status, inclusion: { in: %w[planning active on_hold completed cancelled] }
  validates :budget, numericality: { greater_than: 0 }, allow_nil: true
  validate :end_date_after_start_date

  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, "must be after start date") if end_date <= start_date
  end
end
