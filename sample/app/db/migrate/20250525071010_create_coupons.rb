class CreateCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :coupons do |t|
      t.string :code
      t.string :discount_type
      t.decimal :discount_value
      t.decimal :min_order_amount
      t.integer :max_uses
      t.integer :uses_count
      t.date :valid_from
      t.date :valid_until

      t.timestamps
    end
    add_index :coupons, :code, unique: true
  end
end
