class HomepageController < ApplicationController

	before_filter RubyCAS::Filter, :only => [ :profile ]
	
	def logout
		RubyCAS::Filter.logout(self)
	end
	
	def profile
		@title = "Profile"
		@user = current_user
		raise "No current user?" if !@user
	end
	
	def save_profile # POST
		if params[:user][:name] !~ /^[^\s][^\s]+(\s+[^\s][^\s]+)+$/
			render :text => 'Will not work! Enter a valid name.'
			return
		end
		if params[:user][:mail] !~ /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/
			render :text => 'Will not work! Enter a valid email address.'
			return
		end

		@user = current_user
		@user.update_attributes(params[:user])
		redirect_to :root
	end
	
end
