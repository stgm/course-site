class WelcomeController < ApplicationController

	skip_before_filter :check_repo
	skip_before_filter :require_one_admin_user

	prepend_before_filter CASClient::Frameworks::Rails::Filter
	
	def index

	end

	def clone
		render layout:nil
	end

	def claim
		# if no admin is defined
		unless Settings['admins'] && Settings['admins'].size > 0
			logger.debug session[:cas_user]
			Settings['admins'] = [ session[:cas_user] ]
			redirect_to :root
		end
	end
	
end
