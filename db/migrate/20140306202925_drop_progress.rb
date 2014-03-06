class DropProgress < ActiveRecord::Migration
	def up
		drop_table :progresses
	end

	def down
	end
end
