class ApplicationController < ActionController::Base

	protect_from_forgery

	before_filter :require_one_admin_user
	before_filter :load_navigation

	helper_method :current_user, :logged_in?
	
	def require_one_admin_user
		unless Settings['admins'] && Settings['admins'].size > 0
			redirect_to welcome_claim_url
		end
	end
	
	def load_navigation
		@sections = Section.includes(pages: :pset)
	end
	
	def logged_in?
		return !!session[:cas_user]
	end
	
	def current_user
		@current_user ||= logged_in? && User.where(:uvanetid => session[:cas_user]).first || User.new
	end
	
	def require_admin
		redirect_to :root unless current_user.is_admin?
	end
	
	def require_admin_or_assistant
		redirect_to :root unless current_user.is_admin? or current_user.is_assistant?
	end
	
end
