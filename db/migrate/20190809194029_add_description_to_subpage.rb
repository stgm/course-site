class AddDescriptionToSubpage < ActiveRecord::Migration
  def change
    add_column :subpages, :description, :text
  end
end
