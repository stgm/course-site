class AdminController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	def index
		
	end
	
	# show admins and assistants
	def admins
		@admins = Settings.admins.join("\n")
		@assistants = (Settings.assistants || []).join("\n")
	end
	
	# store new admins list
	def admins_save
		Settings.admins = params[:admins].split(/\r?\n/)
		redirect_to :back
	end
	
	# store new assistants list
	def assistants_save
		Settings.assistants = params[:assistants].split(/\r?\n/)
		redirect_to :back
	end
	
	def dump_grades
		@grades = Grade.joins(:submit).includes(:submit => [:pset,:user]).where("grades.submit_id is not null").order("psets.name")
		render layout:nil
	end
	
	def stats
		
		# wie het vak gehaald heeft
		# wie afgelopen 3 weken nog ingelogd is
		
		@tracks = []
		
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
				@tracks << [track.name, @active_users.count, @done_users.count]
			end
		else
			@active_users = User.active.not_admin.count
			@done_users = nil
		end
		
		render layout: nil
	end
		
end
