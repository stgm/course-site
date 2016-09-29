class WelcomeController < ApplicationController

	before_filter CASClient::Frameworks::Rails::GatewayFilter

	# welcome#index allows claiming of website
	def index
		if authenticated?
			unless User.where(role: User.roles['admin']) > 0
				current_user.admin!
			end
		end
	end

end
