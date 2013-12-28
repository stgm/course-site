class Track

	def self.for(user)
		tracks = {}
		if Course.tracks
			Course.tracks.each do |track_name, track|
				all = Pset.where("psets.name" => track['requirements'])
				done = Pset.includes(:submits).where("submits.user_id" => user.id, "psets.name" => track['requirements'])
				if done != []
					status = {}
					all.each do |pset|
						status[pset.name] = done.include? pset
					end
					tracks[Course.tracks[track_name]['name']] = [done.size * 100 / all.size , status]
				end
			end
		end
		return tracks
	end
	
end
