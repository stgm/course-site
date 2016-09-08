require 'date'

class ApplicationController < ActionController::Base

	protect_from_forgery

	before_action :load_navigation
	before_action :load_schedule
	before_action :register_attendance

	helper_method :current_user, :logged_in?, :authenticated?
	
	def register_attendance
		if current_user.persisted? && request_from_local_network?
			AttendanceRecord.create_for_user(current_user)
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
		return !!(request.remote_ip =~ /^145\.18\..*$/) || !!(request.remote_ip =~ /^145\.109\..*$/) || !!(request.remote_ip =~ /^195\.169\..*$/) || request.remote_ip == '::1' || request.remote_ip == '127.0.0.1'
	end
	
	def load_navigation
		@sections = Section.includes(pages: :pset).order("pages.position")
		@sections = @sections.where("pages.public" => true) unless current_user.is_admin? or current_user.is_assistant?
		@assist_available = User.where('available > ?', DateTime.now).count
	end
	
	def load_schedule
		@schedule = Settings.schedule_position && ScheduleSpan.find_by_id(Settings.schedule_position)
		@alerts = Alert.order("created_at desc")
	end
	
	def authenticated?
		return !!session[:cas_user]
	end
	
	def logged_in?
		return authenticated? && @current_user.persisted?
	end
	
	def current_user
		if @current_user
			# cached (per request)
			return @current_user
		elsif login = Login.where(login: session[:cas_user]).first
			@current_user = login.user
		else
			# no session, so fake empty user
			@current_user = User.new
		end
		
		return @current_user
	end
	
	def require_admin
		redirect_to :root unless current_user.is_admin?
	end
	
	def require_admin_or_assistant
		redirect_to :root unless current_user.is_admin? or current_user.is_assistant?
	end
	
	def default_url_options(options={})
		# { :protocol => 'https' }
		options
	end 
	
end
