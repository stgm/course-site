class AddProgressToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :progress, :text
  end
end
