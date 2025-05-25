class Review < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :rating, :title, :content, presence: true
  validates :rating, inclusion: { in: 1..5 }
  validates :title, length: { maximum: 100 }
  validates :content, length: { maximum: 1000 }
end
