class WelcomeController < ApplicationController

	before_filter CASClient::Frameworks::Rails::GatewayFilter
	
	def index
		if logged_in?
			unless Settings['admins'] && Settings['admins'].size > 0
				Settings['admins'] = [ session[:cas_user] ]
			end
			redirect_to config_url and return
		end
	end

end
