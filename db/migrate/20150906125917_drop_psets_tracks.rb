class DropPsetsTracks < ActiveRecord::Migration
	def change
		drop_table :psets_tracks
	end
end
