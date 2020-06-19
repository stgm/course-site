class AddContentLinksToMod < ActiveRecord::Migration[6.0]
  def change
    add_column :mods, :content_links, :text
  end
end
