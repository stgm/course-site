class WelcomeController < ApplicationController

	before_filter CASClient::Frameworks::Rails::GatewayFilter

	# welcome#index allows claiming of website
	def index
		if logged_in?
			unless User.where(role: User.roles['admin']).count > 0
				current_user.admin!
			end
		end
	end

end
