class WelcomeController < ApplicationController

	before_filter CASClient::Frameworks::Rails::GatewayFilter

	# welcome#index allows claiming of website
	def index
		if authenticated?
			unless Settings['admins'] && Settings['admins'].size > 0
				Settings['admins'] = [ session[:cas_user] ]
				current_user.admin!
			end
			# redirect_to config_path and return
		end
	end

end
