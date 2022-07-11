class HomeController < ApplicationController

	include NavigationHelper
    include AttendanceRecorder

	before_action :authorize, except: [ :homepage ]
	layout 'sidebar'

	def homepage
		if User.admin.none?
			redirect_to welcome_path
		elsif logged_in? && alerts_for_current_schedule.any? || !(current_schedule && current_schedule.page || Page.find_by_slug(''))
			# show announcements page if no syllabus in repo or if there are ann to show at all
			redirect_to action: "announcements"
		else
			redirect_to syllabus_path
		end
	end

	def announcements
		@title = t(:announcements)
	end

end
