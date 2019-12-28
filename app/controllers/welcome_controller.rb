class WelcomeController < ApplicationController

	before_action :authorize, except: [ :index ]

	def index
		if not authenticated?
			# falls through to the welcome page, which links to registration
		elsif not logged_in?
			# Please register
			redirect_to action:'register' and return
		end
	end
	
	def register
		if logged_in?
			unless User.where(role: User.roles['admin']).count > 0
				current_user.admin!
				redirect_to config_path and return
			end
		end
		# if current_user.admin?
		# 	redirect_to config_path and return
		# else
		# 	redirect_to root_path
		# end
	end

end
