class SecondaryUser < SecondaryDatabase
  self.table_name = 'users'
  
  has_many :blog_posts, class_name: 'SecondaryBlogPost', foreign_key: 'user_id'
  has_many :comments, class_name: 'SecondaryComment', foreign_key: 'user_id'
end
