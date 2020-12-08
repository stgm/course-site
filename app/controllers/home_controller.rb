class HomeController < ApplicationController

	include NavigationHelper

	before_action :authorize, except: [ :homepage, :syllabus ]
	before_action :validate_profile
	before_action :register_attendance
	
	layout 'sidebar'

	def homepage
		if User.admin.none?
			redirect_to welcome_path
		elsif logged_in? && alerts_for_current_schedule.any? || !(current_schedule && current_schedule.page || Page.find_by_slug(''))
			# show announcements page if no syllabus in repo or if there are ann to show at all
			redirect_to action: "announcements"
		else
			redirect_to action: "syllabus"
		end
	end

	def submissions
		@student = User.includes(:hands, :notes).find(current_user.id)
		@items = @student.items
		raise ActionController::RoutingError.new('Not Found') if @items.empty?

		# overview table
		@overview_config = Settings.overview_config
		@grades_by_pset = @student.submits.joins(:grade).includes(:grade, :pset).where(grades: { status: Grade.statuses[:published] }).to_h { |item| [item.pset.name, item.grade] }

		@title = t(:submissions)
	end

	def announcements
		@title = t(:announcements)
	end

	def syllabus
		# TODO
		@page = current_schedule && current_schedule.page || Page.find_by_slug('')
		raise ActionController::RoutingError.new('Not Found') if !@page
		@subpages = @page.subpages
		@title = t(:syllabus)
		render "page/index"
	end

end
