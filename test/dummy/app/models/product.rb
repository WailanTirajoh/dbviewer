class Product < ApplicationRecord
  belongs_to :product_category
  has_many :order_items, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :cart_items, dependent: :destroy

  validates :name, :price, :sku, presence: true
  validates :sku, uniqueness: true
  validates :price, numericality: { greater_than: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
end
