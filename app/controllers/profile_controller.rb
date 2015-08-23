class ProfileController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	
	def logout
		CASClient::Frameworks::Rails::Filter.logout(self)
	end
	
	def index
		@title = "Profile"
	end
	
	def pair
		current_user.generate_pairing_code!
		render text: "Pairing code is #{"%04d" % current_user.token}"
	end
	
	def grades
		if Settings.public_grades
			@grades = Grade.includes(:submit).where("submits.user_id = ? and grades.grade is not null", current_user.id).references(:submits)
		end
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

		# if current_user.persisted?
			current_user.update_attributes(params[:user])
		# else
		# 	User.where(:uvanetid => session[:cas_user]).first_or_create do |u|
		# 		u.update_attributes(params[:user])
		# 	end
		# end
		redirect_to :back
	end
	
	def ask
		AskMailer.ask_me_anything(current_user, params['question']).deliver_later
		flash[:notice] = "Your question has been received! Expect an answer sometime soon."
		redirect_to :back
	end
	
end
