class AddLastKnownIpToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_known_ip, :string
  end
end
