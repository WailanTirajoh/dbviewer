class Order < ApplicationRecord
  belongs_to :user
  belongs_to :shipping_address, class_name: "Address", optional: true
  belongs_to :billing_address, class_name: "Address", optional: true
  has_many :order_items, dependent: :destroy
  has_many :order_coupons, dependent: :destroy
  has_many :coupons, through: :order_coupons

  validates :total_amount, :status, :order_date, presence: true
  validates :total_amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending processing shipped delivered cancelled] }

  scope :by_status, ->(status) { where(status: status) }
end
