class CreateSecondaryBlogPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.string :slug
      t.string :status, default: 'draft'
      t.integer :view_count, default: 0
      t.datetime :published_at
      
      t.timestamps
    end
    
    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :status
    add_index :blog_posts, :published_at
  end
end
