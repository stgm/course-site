class HomeController < ApplicationController
	
	include NavigationHelper

	before_action :authorize, except: [ :homepage, :syllabus ]
	before_action :register_attendance

	def homepage
		if User.admin.none? || Page.none?
			redirect_to welcome_path
		elsif Page.where(section_id: nil).none? || logged_in? && alerts_for_current_schedule.any?
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

		render layout: 'boxes'
	end
	
	def announcements
		@title = "#{Settings.course["short_name"]} #{t(:announcements)}" if Settings.course
		render layout: 'boxes'
	end
	
	def staff
		render status: :forbidden and return if not logged_in? && current_user.senior?

		@student = User.includes(:hands, :notes).find(current_user.id)
		@note = Note.new(student_id: @student.id)
		@notes = Note.all.order("updated_at desc")
		
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
		@page = Page.where(section_id: nil).first
		raise ActionController::RoutingError.new('Not Found') if !@page
		# if there's a subpage titled with the name of the current schedule, display that, otherwise the subpage numbered 0
		@subpages = [current_schedule && @page.subpages.where(title: current_schedule.name).first || @page.subpages.where(position: 0).first || @page.subpages.first]
		@title = "#{Settings.course["short_name"]}  #{t(:syllabus)}"
		render "page/index"
	end
	
end
