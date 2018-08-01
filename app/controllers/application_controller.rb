require 'date'

class ApplicationController < ActionController::Base

	protect_from_forgery with: :exception
	
	rescue_from ActionController::InvalidAuthenticityToken do |exception|
		flash[:alert] = "<strong>Warning:</strong> you were logged out since you last loaded this page. If you just submitted, please login and try again.".html_safe
		redirect_to :back
	end
	
	before_action :load_navigation
	before_action :load_schedule

	helper_method :current_user, :logged_in?, :authenticated?
	
	def register_attendance
		if current_user.persisted? #&& request_from_local_network?
			AttendanceRecord.create_for_user(current_user, request_from_local_network?)
		end
	end
	
	def request_from_local_network?
		@request_from_local_network ||= is_local_ip?
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
			@sections = Section.where("sections.display" => true).includes(pages: :pset).where("pages.public" => true).order("pages.position")
		end
	end
	
	def load_schedule
		# load schedule
		if s = current_user.schedule
			@schedule = s.current
			@schedule_name = s.name
			@group_name = current_user.group.name if current_user.group
		end
		
		# load alerts
		alert_sources = [nil]
		alert_sources.append s.id if s
		@alerts = Alert.where(schedule_id: alert_sources).order("created_at desc")
	end
	
	def authenticated?
		return !!session[:cas_user]
	end
	
	def logged_in?
		return authenticated? && current_user.persisted?
	end
	
	def current_user
		return @current_user || load_current_user
	end
	
	def load_current_user
		if login = Login.where(login: session[:cas_user]).first
			@current_user = login.user
		else
			# no session, so fake empty user
			@current_user = User.new
		end
		
		return @current_user
	end
	
	def redirect_back_with(warning)
		destination = request.referer || path_to(:root)
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
