class ApplicationController < ActionController::Base

	protect_from_forgery
	
	def logged_in?
		return session[:cas_user] != nil
	end
	
	def current_user
		return logged_in? && User.where(:uvanetid => session[:cas_user]).first_or_create
	end
	
	def is_admin?
		admins = ['mstegem1']
		return current_user && admins.include?(session[:cas_user])
	end

end
