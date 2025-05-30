class CreateSecondaryUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :email, null: false
      t.string :password_digest
      t.boolean :admin, default: false
      t.string :api_token
      t.string :status, default: "active"
      t.date :last_login_at

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
    add_index :users, :api_token, unique: true
  end
end
