class CreateProductCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :product_categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :parent_id

      t.timestamps
    end

    add_index :product_categories, :parent_id
    add_foreign_key :product_categories, :product_categories, column: :parent_id
  end
end
