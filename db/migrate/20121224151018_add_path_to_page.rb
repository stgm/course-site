class AddPathToPage < ActiveRecord::Migration
  def change
    add_column :pages, :path, :string
  end
end
