class Address < ApplicationRecord
  belongs_to :user
  has_many :shipping_orders, class_name: "Order", foreign_key: "shipping_address_id"
  has_many :billing_orders, class_name: "Order", foreign_key: "billing_address_id"

  validates :street_address, :city, :state, :country, :address_type, presence: true
  validates :address_type, inclusion: { in: %w[shipping billing both] }
end
