class CreateTracks < ActiveRecord::Migration
	def change
		create_table :tracks do |t|
			t.integer :final_grade_id, index: { name: 'index_tracks_on_final_grade_id' }
			t.string :name
			t.timestamps
		end
	end
end
