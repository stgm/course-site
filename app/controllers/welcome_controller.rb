class WelcomeController < ApplicationController

	before_filter CASClient::Frameworks::Rails::GatewayFilter

	# welcome#index allows claiming of website
	def index
		if not authenticated?
			# Please login
		elsif not logged_in?
			# Please register
			redirect_to profile_path and return
		else
			# Please admin all the things
			if logged_in?
				unless User.where(role: User.roles['admin']).count > 0
					current_user.admin!
				end
			end
			if current_user.admin?
				redirect_to config_path and return
			end
		end
	end

end
