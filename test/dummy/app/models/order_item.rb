class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, :unit_price, :total_price, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, :total_price, numericality: { greater_than: 0 }

  before_save :calculate_total_price

  private

  def calculate_total_price
    self.total_price = quantity * unit_price if quantity && unit_price
  end
end
