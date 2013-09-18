class ProfileController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter, :only => [ :profile ]
	
	def logout
		CASClient::Frameworks::Rails::Filter.logout(self)
	end
	
	def index
		@title = "Profile"
	end
	
	def grades
		@grades = Grade.includes(:submit).where("submits.user_id = ?", current_user.id)
	end
	
	def save # POST
		if params[:user][:name] !~ /^[^\s][^\s]+(\s+[^\s][^\s]+)+$/
			render :text => 'Will not work! Enter a valid name.'
			return
		end
		if params[:user][:mail] !~ /^[A-Za-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/
			render :text => 'Will not work! Enter a valid email address.'
			return
		end

		current_user.update_attributes(params[:user])
		redirect_to :root
	end
	
end
