class CreateSchedules < ActiveRecord::Migration
	def change
		create_table :schedules do |t|
			t.string :name
			t.references :track
			t.text :description

			t.timestamps
		end
		add_index :schedules, :track_id
	end
end
