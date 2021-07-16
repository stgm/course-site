class DropSections < ActiveRecord::Migration[6.0]
	def change
		drop_table :sections, {}
	end
end
