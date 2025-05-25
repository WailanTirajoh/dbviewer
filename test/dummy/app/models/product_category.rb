class ProductCategory < ApplicationRecord
  belongs_to :parent, class_name: "ProductCategory", optional: true
  has_many :children, class_name: "ProductCategory", foreign_key: "parent_id", dependent: :destroy
  has_many :products, dependent: :destroy

  validates :name, presence: true

  scope :root_categories, -> { where(parent_id: nil) }
end
