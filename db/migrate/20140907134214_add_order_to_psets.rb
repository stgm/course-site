class AddOrderToPsets < ActiveRecord::Migration
  def change
    add_column :psets, :order, :integer
  end
end
