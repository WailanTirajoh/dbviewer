class CreateOffices < ActiveRecord::Migration[8.0]
  def change
    create_table :offices do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.text :address
      t.string :city
      t.string :state
      t.string :country
      t.string :postal_code
      t.string :phone
      t.integer :capacity

      t.timestamps
    end
  end
end
