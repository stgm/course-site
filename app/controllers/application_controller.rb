class ApplicationController < ActionController::Base

	protect_from_forgery

	before_filter :check_admins
	before_filter :load_navigation

	helper_method :current_user, :logged_in?, :known_user?, :valid_profile?, :is_admin?, :is_assistant?
	
	def check_admins
		# if no admin is defined
		unless Settings['admins'] && Settings['admins'].size > 0
			redirect_to welcome_claim_url
		end
	end
	
	def current_user
		@current_user ||= logged_in? && User.where(:uvanetid => session[:cas_user]).first #_or_create
	end
	
	def logged_in?
		return !!session[:cas_user]
	end
	
	def valid_profile?
		Rails.logger.debug (!!current_user && !current_user.name.blank?).inspect
		!!current_user && !current_user.name.blank?
		# not current_user.name.nil? and current_user.name != ''
	end
	
	def known_user?
		valid_profile?
	end
	
	def is_admin?
		admins = Settings['admins']
		return current_user && admins && admins.include?(session[:cas_user].to_s)
	end
	
	def is_assistant?
		assistants = Settings['assistants']
		return current_user && assistants && assistants.include?(session[:cas_user].to_s)
	end
	
	def load_navigation
		@sections = Section.includes(pages: :pset)
	end
	
	def require_admin
		redirect_to :root unless is_admin?
	end
	
	def require_admin_or_assistant
		redirect_to :root unless is_admin? or is_assistant?
	end
	
	def redirect_to_profile
		if logged_in? and not valid_profile?
			redirect_to controller: 'profile'
		end
	end

end
