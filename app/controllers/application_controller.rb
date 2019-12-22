require 'date'

class ApplicationController < ActionController::Base

	rescue_from ActionController::InvalidAuthenticityToken do |exception|
		flash[:alert] = "<strong>Warning:</strong> you were logged out since you last loaded this page. If you just submitted, please login and try again.".html_safe
		redirect_back fallback_location: '/'
	end
	
	before_action :set_locale
	
	def set_locale
	  I18n.locale = (Settings.course["language"] if Settings.course) || I18n.default_locale
	end

	helper_method :current_user, :logged_in?, :authenticated?
	
	def register_attendance
		if (!session[:last_seen_at] || session[:last_seen_at] && session[:last_seen_at] < 15.minutes.ago) && current_user.persisted?
			AttendanceRecord.create_for_user(current_user, request_from_local_network?)
			session[:last_seen_at] = DateTime.now
		end
	end
	
	def request_from_local_network?
		@request_from_local_network ||= is_local_ip?
	end
	
	def go_location_bumper
		redirect_to(location_path) if Settings.hands_bumper && request_from_local_network? && current_user.student? && current_user.last_known_location.blank?
	end
	
	def is_local_ip?
		# begin
		# 	location = Resolv.getname(request.remote_ip)
		# rescue Resolv::ResolvError
		# 	location = "untraceable"
		# end
		# puts "loc" + location
		# return location =~ /^(wcw|1x).*uva.nl$/ || location == 'localhost'
		# puts request.remote_ip
		return !!(request.remote_ip =~ /^145\.18\..*$/) ||
		       !!(request.remote_ip =~ /^145\.109\..*$/) ||
			   !!(request.remote_ip =~ /^195\.169\..*$/) ||
			   !!(request.remote_ip =~ /^100\.70\..*$/) ||
			   request.remote_ip == '::1' ||
			   request.remote_ip == '127.0.0.1'
	end
	
	def load_navigation
		if current_user.staff?
			@sections = Section.includes(pages: :pset).order("pages.position")
		else
			@sections = Section.includes(pages: :pset).where("pages.public" => true).order("pages.position")
		end
	end
	
	def load_schedule
		# if user switched schedules, may lack current_module TODO move to user model on change schedule
		current_user.check_current_module
		
		# load schedule
		if @schedule = current_user.schedule
			if @schedule.self_service
				@current_schedule = current_user.current_module || @schedule.current
			else
				@current_schedule = @schedule.current
			end
			if Schedule.count > 1
				@schedule_name = @schedule.name
				@group_name = current_user.group.name if current_user.group
			end
		end
		
		# load alerts
		alert_sources = [nil]
		alert_sources.append @schedule.id if @schedule
		@alerts = Alert.where(schedule_id: alert_sources).order("created_at desc")
	end
	
	def authorize
		# defer login to rack-cas
		head :unauthorized unless request.session['cas'].present?
	end
 
	def authenticated?
		return request.session['cas'].present?
	end
	
	def logged_in?
		return authenticated? && current_user.persisted?
	end
	
	def current_user
		return @current_user || load_current_user
	end
	
	def load_current_user
		if authenticated? && login = Login.where(login: request.session['cas']['user']).first
			@current_user = login.user
		else
			# use an empty user object in case of no login
			@current_user = User.new
		end
		
		return @current_user
	end
	
	def redirect_back_with(warning)
		destination = request.referer || :root
		redirect_to destination, alert: warning
	end
	
	#
	# role based permissions
	#
	# staff = admin + head + assistant
	# student = student
	# guest = guest
	#
	
	def require_admin
		redirect_to :root unless current_user.admin?
	end
	
	def require_senior
		redirect_to :root unless current_user.head? or current_user.admin?
	end
	
	def require_staff
		redirect_to :root unless current_user.admin? or current_user.assistant? or current_user.head?
	end
	
	def default_url_options(options={})
		# { :protocol => 'https' }
		options
	end 
	
end
