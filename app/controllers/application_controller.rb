class ApplicationController < ActionController::Base

	protect_from_forgery
	
	helper_method :logged_in?, :is_admin?
	
	def logged_in?
		return !!session[:cas_user]
	end
	
	def current_user
		return logged_in? && User.where(:uvanetid => session[:cas_user]).first_or_create
	end
	
	def is_admin?
		admins = Course.security['professors']
		return current_user && admins && admins.include?(session[:cas_user].to_s)
	end
	
end
