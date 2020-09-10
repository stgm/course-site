class DropMod < ActiveRecord::Migration[6.0]
	def change
		drop_table :mods, {}
	end
end
