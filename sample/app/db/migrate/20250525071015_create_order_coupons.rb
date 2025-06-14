class CreateOrderCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :order_coupons do |t|
      t.references :order, null: false, foreign_key: true
      t.references :coupon, null: false, foreign_key: true
      t.decimal :discount_applied

      t.timestamps
    end
  end
end
