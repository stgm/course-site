class AddFilesToPset < ActiveRecord::Migration
  def change
    add_column :psets, :files, :text
  end
end
