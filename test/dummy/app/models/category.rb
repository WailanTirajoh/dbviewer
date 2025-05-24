class Category < ApplicationRecord
  has_many :articles, dependent: :destroy
end
