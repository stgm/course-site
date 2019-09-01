class HomeController < ApplicationController

	prepend_before_action CASClient::Frameworks::Rails::GatewayFilter, only: [ :homepage, :syllabus ]
	prepend_before_action CASClient::Frameworks::Rails::Filter, except: [ :homepage, :syllabus ]

	before_action :register_attendance
	
	def homepage
		if not Page.any?
			# no pages at all means probably not configured yet
			if User.admin.any?
				# there's already an admin, go to config, will force login
				redirect_to config_path
			else
				# there's no admin yet, make current user admin
				redirect_to welcome_register_path
			end
		elsif logged_in? && @alerts.any?
			redirect_to action: "announcements"
		else
			redirect_to action: "syllabus"
		end
	end

	def submissions
		@schedules = Schedule.all
		@student = User.includes(:hands, :notes).find(current_user.id)
		@grades = Grade.published.joins(:submit).includes(:submit).where('submits.user_id = ?', current_user.id).order('grades.created_at desc')
	
		@items = []
		@items += @student.submits.where("submitted_at not null").to_a
		@items += @grades.to_a
		@items = @items.sort { |a,b| b.created_at <=> a.created_at }
	end
	
	def announcements
		redirect_to :root and return if not logged_in?

		@student = User.includes(:hands, :notes).find(current_user.id)
		@note = Note.new(student_id: @student.id)
		
		if current_user.senior? && current_user.schedule
			@groups = current_user.schedule.groups.order(:name)
			# @psets = current_user.schedule.grades.finished.joins(:submit => :pset).group("psets.name").count
			logger.info "loading"
			@psets = current_user.schedule.grades.finished.joins(:submit => :pset).group("psets.id", "psets.name").count
			@new_students = current_user.schedule.users.not_staff.groupless.active
		end
		
		@title = "#{Settings.course["short_name"]} #{t(:announcements)}" if Settings.course
	end
	
	def staff
		render status: :forbidden and return if not logged_in? && current_user.senior?

		@student = User.includes(:hands, :notes).find(current_user.id)
		@note = Note.new(student_id: @student.id)
		
		if current_user.senior? && current_user.schedule
			@groups = current_user.schedule.groups.order(:name)
			# @psets = current_user.schedule.grades.finished.joins(:submit => :pset).group("psets.name").count
			logger.info "loading"
			@psets = current_user.schedule.grades.finished.joins(:submit => :pset).group("psets.id", "psets.name").count
			@new_students = current_user.schedule.users.not_staff.groupless.active
		end
		
		@title = "#{Settings.course["short_name"]} #{t(:announcements)}" if Settings.course
	end
	
	def syllabus
		# the normal homepage is the page without a parent section
		@page = Page.where(:section_id => nil).first
		# if there's a subpage titled with the name of the current schedule, display that, otherwise the subpage numbered 0
		@subpages = [@schedule && @page.subpages.where(title: @schedule.name).first || @page.subpages.where(position: 0).first || @page.subpages.first]
		@title = "#{Settings.course["short_name"]}  #{t(:syllabus)}"
		raise ActionController::RoutingError.new('Not Found') if !@page
		render "page/index"
	end
	
end
