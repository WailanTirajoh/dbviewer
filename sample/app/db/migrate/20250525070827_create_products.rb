class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :sku
      t.integer :stock_quantity
      t.references :product_category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :products, :sku, unique: true
  end
end
