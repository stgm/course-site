class AddHintToHand < ActiveRecord::Migration[7.0]
  def change
    add_column :hands, :hint, :string
  end
end
