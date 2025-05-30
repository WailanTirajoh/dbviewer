class CreateSecondaryComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.text :content, null: false
      t.references :blog_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :approved, default: false
      t.integer :parent_id
      
      t.timestamps
    end
    
    add_index :comments, :parent_id
    add_index :comments, :approved
  end
end
