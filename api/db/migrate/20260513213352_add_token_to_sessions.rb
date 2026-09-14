class AddTokenToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :auth_token, :string
    add_index :sessions, :auth_token, unique: true
  end
end
