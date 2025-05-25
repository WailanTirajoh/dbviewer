class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone
      t.date :date_of_birth

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
