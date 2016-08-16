class AddLastSeenToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_seen_at, :datetime
    add_column :users, :last_spoken_at, :datetime
  end
end
