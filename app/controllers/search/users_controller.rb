class Search::UsersController < ApplicationController
	
	before_action :authorize
	before_action :require_senior

	# GET /search/users?text=.. for admins + heads
	def show
		if params[:text] != ""
			@results = User.joins(:logins).where("users.name like ? or logins.login like ?", "%#{params[:text]}%", "%#{params[:text]}%").limit(10).order(:name)
		else
			@results = []
		end
		
		respond_to do |format|
			format.js
		end
	end
	
end
