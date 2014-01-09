class Track < ActiveRecord::Base
	
	has_and_belongs_to_many :psets
	belongs_to :final_grade, class_name: 'Pset'#, foreign_key: 'id'

	def self.for(user)
		tracks = {}
		if Track.any?
			Track.all.each do |track|
				all = Pset.where("psets.id" => track.psets)
				done = Pset.includes(:submits).where("submits.user_id" => user.id, "psets.id" => track.psets)
				if done != []
					status = {}
					all.each do |pset|
						status[pset.name] = done.include? pset
					end
					tracks[track.name] = [done.size * 100 / all.size , status]
				end
			end
		end
		return tracks
	end
	
end
