class SecondaryComment < SecondaryDatabase
  self.table_name = "comments"

  belongs_to :user, class_name: "SecondaryUser", foreign_key: "user_id"
  belongs_to :blog_post, class_name: "SecondaryBlogPost", foreign_key: "blog_post_id"
  belongs_to :parent, class_name: "SecondaryComment", foreign_key: "parent_id", optional: true
  has_many :replies, class_name: "SecondaryComment", foreign_key: "parent_id"
end
