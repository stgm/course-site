class CreateTracksPsetsTable < ActiveRecord::Migration
	def change
		create_table :psets_tracks do |t|
			t.references :pset
			t.references :track
		end
	    add_index :psets_tracks, [:track_id, :pset_id]
	    add_index :psets_tracks, :track_id
	end
end
