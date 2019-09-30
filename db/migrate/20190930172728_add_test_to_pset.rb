class AddTestToPset < ActiveRecord::Migration
  def change
    add_column :psets, :test, :boolean
  end
end
