class ApplicationController < ActionController::Base

	include AuthenticationHelper

	rescue_from ActionController::InvalidAuthenticityToken do |exception|
		flash[:alert] = "Warning: you were logged out since you last loaded this page. If you just submitted, please login and try again."
		redirect_back fallback_location: '/'
	end

	before_action do # set_locale
		I18n.locale = Course.language || I18n.default_locale
	end

	before_action do # login by token
		if params[:token].present? && User.where(token: params[:token]).any?
			# login via generated token
			request.session['token'] = params[:token]
		end
	end

	##
	## Before-actions

	def authorize
		head :unauthorized unless authenticated?
	end

	def validate_profile
		redirect_to profile_path if authenticated? && !current_user.valid_profile?
	end

	def register_attendance
		if (!session[:last_seen_at] || session[:last_seen_at] && session[:last_seen_at] < 15.minutes.ago) && current_user.persisted?
			AttendanceRecord.create_for_user(current_user, request_from_local_network?)
			session[:last_seen_at] = DateTime.now
		end
	end

	##
	## Role-based permissions

	def require_admin
		redirect_to :root unless current_user.admin?
	end

	def require_senior
		redirect_to :root unless current_user.head? or current_user.admin?
	end

	def require_staff
		redirect_to :root unless current_user.admin? or current_user.assistant? or current_user.head?
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
