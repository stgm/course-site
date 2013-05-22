class ApplicationController < ActionController::Base

	protect_from_forgery
	before_filter :require_users
	helper_method :logged_in?, :is_admin?
	
	def logged_in?
		return !!session[:cas_user]
	end
	
	def current_user
		return logged_in? && User.where(:uvanetid => session[:cas_user]).first_or_create
	end
	
	def is_admin?
		admins = Settings['admins']
		return current_user && admins && admins.include?(session[:cas_user].to_s)
	end
	
	def require_admin
		redirect_to :root unless is_admin?
	end
	
	def require_users
		unless Settings['admins'] && Settings['admins'].size > 0 # if no admin is defined
			redirect_to admin_claim_url
		end
	end
	
end
