class ProfileController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	
	def logout
		CASClient::Frameworks::Rails::Filter.logout(self)
	end
	
	def index
		@title = "Profile"
	end
	
	def grades
		if Settings.public_grades
			@grades = Grade.includes(:submit).where("submits.user_id = ? and grades.grade is not null", current_user.id).references(:submits)
		end
		render layout:'application'
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

		if current_user.persisted?
			current_user.update_attributes(params[:user])
		else
			User.where(:uvanetid => session[:cas_user]).first_or_create do |u|
				u.update_attributes(params[:user])
			end
		end
		redirect_to :root
	end
	
end
