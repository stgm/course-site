class AddPathToSection < ActiveRecord::Migration
  def change
    add_column :sections, :path, :string
  end
end
