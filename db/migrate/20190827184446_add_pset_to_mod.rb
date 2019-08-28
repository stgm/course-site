class AddPsetToMod < ActiveRecord::Migration
	def change
		add_reference :mods, :pset, index: true, foreign_key: true
	end
end
