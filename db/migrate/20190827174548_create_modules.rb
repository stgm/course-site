class CreateModules < ActiveRecord::Migration
	def change
		create_table :mods do |t|
			t.string :name
		end
	end
end
