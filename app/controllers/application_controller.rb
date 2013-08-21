class ApplicationController < ActionController::Base

	protect_from_forgery

	before_filter :check_repo
	before_filter :check_admins
	before_filter :load_navigation

	helper_method :logged_in?, :is_admin?
	
	def check_repo
		unless Course.has_repo?
			redirect_to welcome_clone_url
		end
	end
	
	def check_admins
		unless Settings['admins'] && Settings['admins'].size > 0 # if no admin is defined
			redirect_to welcome_claim_url
		end
	end
	
	def current_user
		return logged_in? && User.where(:uvanetid => session[:cas_user]).first_or_create
	end
	
	def logged_in?
		return !!session[:cas_user]
	end
	
	def is_admin?
		admins = Settings['admins']
		return current_user && admins && admins.include?(session[:cas_user].to_s)
	end
	
	def load_navigation
		@sections = Section.includes(pages: :pset).all
	end
	
end
