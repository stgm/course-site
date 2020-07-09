class WelcomeController < ApplicationController

	before_action :authorize, except: [ :index ]

	def index
		if not authenticated?
			# Welcome, you can start now by trying to auth
		elsif not logged_in?
			# We don't know you yet, please register
			redirect_to action: 'register'
		elsif User.admin.none?
			# Automatically claim admin rights
			redirect_to action: 'claim'
		elsif Settings.git_repo.blank?
			# Please set course repo, or finalizing setting course repo
			redirect_to action: 'clone'
		else
			# Done!
			redirect_to :root
		end
	end
	
	#
	# make whoever registers first into admin
	#
	def register
		#
	end
	
	#
	# gives first registered user admin rights
	#
	def claim
		if logged_in? && User.admin.none?
			current_user.admin!
			redirect_to action: 'index' and return
		end
	end
	
	#
	# allow setting the git repository
	#
	def clone
		if Settings.git_repo.present?
			User.first.update(schedule: Schedule.first)
			redirect_to action: 'index'
		end
	end

end
