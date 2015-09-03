class WelcomeController < ApplicationController

	before_filter CASClient::Frameworks::Rails::GatewayFilter

	# welcome#index allows claiming of website
	def index
		if logged_in?
			unless Settings['admins'] && Settings['admins'].size > 0
				Settings['admins'] = [ session[:cas_user] ]
			end
			# redirect_to config_path and return
		end
	end

end
