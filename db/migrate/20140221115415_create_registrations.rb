class CreateRegistrations < ActiveRecord::Migration

	def up
		create_table :registrations do |t|
			t.references :user
			t.references :track
			t.string :term
			t.string :status

			t.timestamps
		end
		add_index :registrations, :user_id
		add_index :registrations, :track_id
		
		User.not_admin.each do |u|
			Track.all.each do |t|
				psets = t.psets.order("psets_tracks.id")
				if u.submits.joins(:grade).where("submits.pset_id" => t.final_grade.id).count > 0
					Registration.create user:u, track:t, term:"", status:"done"
				elsif u.submits.where("pset_id" => psets).count > 0
					if u.active
						Registration.create user:u, track:t, term:"", status:"active"
					else
						Registration.create user:u, track:t, term:"", status:"inactive"
					end
				end
			end
		end
	end
	
	def down
		remove_index :registrations, :user_id
		remove_index :registrations, :track_id
		drop_table :registrations
	end
	
end
