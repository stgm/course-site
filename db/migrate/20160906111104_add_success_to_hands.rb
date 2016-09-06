class AddSuccessToHands < ActiveRecord::Migration
  def change
    add_column :hands, :success, :boolean
  end
end
