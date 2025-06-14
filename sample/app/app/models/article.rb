class Article < ApplicationRecord
  belongs_to :category, optional: true
end
