class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.string :status, null: false, default: "pending"
      t.datetime :order_date, null: false
      t.integer :shipping_address_id
      t.integer :billing_address_id

      t.timestamps
    end

    add_index :orders, :shipping_address_id
    add_index :orders, :billing_address_id
    add_index :orders, :status
    add_foreign_key :orders, :addresses, column: :shipping_address_id
    add_foreign_key :orders, :addresses, column: :billing_address_id
  end
end
