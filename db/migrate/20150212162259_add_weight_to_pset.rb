class AddWeightToPset < ActiveRecord::Migration
  def change
    add_column :psets, :weight, :integer
  end
end
