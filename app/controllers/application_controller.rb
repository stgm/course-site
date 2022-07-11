class ApplicationController < ActionController::Base

	include Authentication

	rescue_from ActionController::InvalidAuthenticityToken do |exception|
		flash[:alert] = "Warning: you were logged out since you last loaded this page. If you just submitted, please login and try again."
		redirect_back fallback_location: '/'
	end

	before_action do # set_locale
		I18n.locale = Course.language || I18n.default_locale
	end

	before_action do
		# note: using authenticated? ensure that a user is not needlessly loaded
		if authenticated? && current_user.admin?
			if !Settings.site_enabled
				flash[:alert] = "Warning: submit is disabled in settings."
			elsif Settings.site_enabled && !Submit::Webdav::Client.available?
				flash[:alert] = "Warning: submit is enabled, but archival config is missing."
			end
		end
	end

	private

	def request_from_local_network?
		@request_from_local_network ||= is_local_ip?
	end

	def is_local_ip?
		return !!(request.remote_ip =~ /^145\.18\..*$/) ||
		       !!(request.remote_ip =~ /^145\.109\..*$/) ||
			   !!(request.remote_ip =~ /^195\.169\..*$/) ||
			   !!(request.remote_ip =~ /^100\.70\..*$/) ||
			   request.remote_ip == '::1' ||
			   request.remote_ip == '127.0.0.1'
	end

end
