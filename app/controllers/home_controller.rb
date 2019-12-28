class HomeController < ApplicationController

	before_action :authorize, except: [ :homepage, :syllabus ]
	before_action :register_attendance
	
	before_action :load_navigation
	before_action :load_schedule

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
		@grades = Grade.published.joins(:submit).includes(:submit).where('submits.user_id = ?', current_user.id).order('grades.updated_at desc')
	
		@items = []
		@items += @student.submits.includes({:pset => [:parent_mod, :mod]}).where("submitted_at is not null").where("psets.mod_id is not null or mods_psets.pset_id is null").references(:psets, :mods).to_a
		@items += @grades.to_a
		@items = @items.sort { |a,b| b.updated_at <=> a.updated_at }

		# determine the categories to show
		@overview = Settings.grading.select { |category, value| value['show_progress'] }

		@subgrades = {}
		@show_calculated = {}
		@overview.each_pair do |category, content|
			# remove weight 0 and bonus
			@overview[category]['submits'] = @overview[category]['submits'].reject { |submit, weight| (weight == 0 || weight == 'bonus') }

			# determine subgrades
			@subgrades[category] = []
			@show_calculated[category] = false
			@overview[category]['submits'].each_pair do |submit, weight|
				@subgrades[category] += Settings.grading['grades'][submit]['subgrades'].keys if !Settings.grading['grades'][submit]['hide_subgrades']
				@show_calculated[category] = true if !Settings.grading['grades'][submit]['hide_calculated']
			end
			
			# remove dupes
			@subgrades[category] = @subgrades[category].uniq
		end

		# convert grades to an easy-to-use format
		@grades_by_pset = @grades.to_h { |item| [item.pset.name, item] }

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
		@page = Page.where(:section_id => nil).first
		# if there's a subpage titled with the name of the current schedule, display that, otherwise the subpage numbered 0
		@subpages = [@schedule && @page.subpages.where(title: @schedule.name).first || @page.subpages.where(position: 0).first || @page.subpages.first]
		@title = "#{Settings.course["short_name"]}  #{t(:syllabus)}"
		raise ActionController::RoutingError.new('Not Found') if !@page
		render "page/index"
	end
	
end
