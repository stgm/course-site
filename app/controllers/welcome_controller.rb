class WelcomeController < ApplicationController

	before_filter CASClient::Frameworks::Rails::GatewayFilter

	# welcome#index allows claiming of website
	def index
		
		#redirect_to :root if authenticated?
		
		if not authenticated?
			# Please login
		elsif not logged_in?
			redirect_to profile_path and return
		else
			redirect_to admin_path and return
		end
		
		if logged_in?
			unless User.where(role: User.roles['admin']).count > 0
				current_user.admin!
			end
		end
	end

end
