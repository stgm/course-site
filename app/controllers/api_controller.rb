class ApiController < ApplicationController

    before_filter :restrict_access
	
	def students	
		@students = []
		
		if Track.any?
			Track.all.each do |track|
				final_grade = track.final_grade
				psets = track.psets.order("psets_tracks.id")
				users = User.includes({ :submits => :grade }, :psets).where("psets.id" => psets)
				@done_users = users.select do |u|
					u.submits.index { |s| s.pset_id == track.final_grade.id }
				end
				@active_users = users.where(active: true).select do |u|
					!u.submits.index { |s| s.pset_id == track.final_grade.id }
				end
				
				@done_users.each do |u|
					subs = u.submits.includes(:pset).where("psets.id" => psets).order("submits.created_at")
					@students << [Settings['short_course_name'], track.name, u.uvanetid, subs.first.created_at, subs.last.created_at, true]
				end

				@active_users.each do |u|
					subs = u.submits.includes(:pset).where("psets.id" => psets).order("submits.created_at")
					@students << [Settings['short_course_name'], track.name, u.uvanetid, subs.first.created_at, subs.last.created_at, false]
				end
			end
		end
		
		render json: @students
	end

	private
	
	def restrict_access
		authenticate_or_request_with_http_token do |token, options|
			Settings.apikey == token
		end
	end

end
