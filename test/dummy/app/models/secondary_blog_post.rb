class SecondaryBlogPost < SecondaryDatabase
  self.table_name = "blog_posts"

  belongs_to :user, class_name: "SecondaryUser", foreign_key: "user_id"
  has_many :comments, class_name: "SecondaryComment", foreign_key: "blog_post_id"
end
