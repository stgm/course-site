class DropPings < ActiveRecord::Migration[6.0]
	def change
		drop_table :pings, {}
	end
end
