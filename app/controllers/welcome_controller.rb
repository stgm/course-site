class WelcomeController < ApplicationController

	skip_before_filter :check_repo, only: [ :clone ]

	prepend_before_filter CASClient::Frameworks::Rails::Filter
	
	def index
		@user = current_user
	end

	def clone
		render layout:nil
	end

	def claim
		# if no admin is defined
		unless Settings['admins'] && Settings['admins'].size > 0
			Settings['admins'] = [ session[:cas_user] ]
			redirect_to :root
		end
	end
	
end
