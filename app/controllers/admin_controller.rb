class AdminController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	def index
		
	end
	
	def api
		@apikey = Settings.apikey
	end
	
	def api_save
		Settings.apikey = params[:apikey]
		redirect_to :back
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
		
		terms = Registration.select(:term)
		
		@tracks = []
		
		if Track.any?
			terms.each do |term|
				Track.all.each do |track|
					users = track.users.from_term(term.term)
					done_users = users.having_status('done')
					active_users = users.having_status('active')
					missing_users = users.having_status('MIA')
					@tracks << [term.term, track.name, active_users.count, done_users.count, missing_users.count]
				end
			end
		else
			@active_users = User.active.not_admin.count
			@done_users = nil
		end
		
		render layout: nil
	end
		
end
