class RemoveContentLinksFromMod < ActiveRecord::Migration[6.0]
	def change
		remove_column :mods, :content_links, :text
	end
end
