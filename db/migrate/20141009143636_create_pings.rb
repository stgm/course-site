class CreatePings < ActiveRecord::Migration
	def change
		create_table :pings do |t|
			t.references :user, index: true
			t.integer :loca
			t.integer :locb
			t.boolean :help
			t.boolean :active
			t.timestamps
		end
	end
end
