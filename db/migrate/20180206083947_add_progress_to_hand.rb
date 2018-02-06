class AddProgressToHand < ActiveRecord::Migration
  def change
    add_column :hands, :progress, :string
  end
end
