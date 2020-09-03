class OverviewsController < ApplicationController

	before_action :authorize
	before_action :require_staff

	layout 'schedules'

	def show
		if current_user.assistant?
			redirect_back(fallback_location: '/', alert: "You haven't been assigned a group yet!") and return if current_user.groups.empty?
			slug = current_user.groups.first
			redirect_to(group_overview_path(slug: slug)) and return if slug.present?
		elsif current_user.head?
			redirect_back(fallback_location: '/', alert: "You haven't been assigned a schedule yet!") and return if current_user.schedules.empty?
			slug = current_user.schedules.first
			redirect_to(schedule_overview_path(slug: slug)) and return if slug.present?
		elsif current_user.admin?
			# default to currently selected schedule
			slug = current_user.schedule
			redirect_to(schedule_overview_path(slug: slug)) and return if slug.present?
		end

		redirect_back(fallback_location: '/', alert: 'No schedules') and return if slug.blank?
	end

	def group
		# check which schedules this user is allowed to view
		@accessible_schedules = current_user.groups
		@selected_schedule = Group.friendly.find(params[:slug])

		# [["Problems", ["M1", "M2", "M3", ...]], ...]
		@overview = Settings.grading.select { |c,v| v['show_progress'] }.map { |c,v| [c, v['submits'].map {|k,v| k}] }

		@name = @selected_schedule.name
		@status = params[:status]
		@psets = Pset.ordered_by_grading #Pset.order(:order)
		@grouped_psets = @psets.group_by &:name

		@users = @selected_schedule.users.not_staff.includes(:group, { submits: [:pset, :grade] }).order("groups.name").order(:name)
		@title = 'List users'

		@active_count = @users.active.count
		@registered_count = @users.registered.count
		@inactive_count = @users.inactive.count
		@done_count = @users.done.count

		case params[:status]
		when 'active'
			@users = @users.active
		when 'registered'
			@users = @users.registered
		when 'inactive'
			@users = @users.inactive
		when 'done'
			@users = @users.done
		end

		@users = @users.group_by(&:group)

		if current_user.assistant?
			render 'overview'
		else
			render 'show'
		end
	end

	def schedule
		# check which schedules this user is allowed to view
		@accessible_schedules = current_user.accessible_schedules
		@selected_schedule = Schedule.friendly.find(params[:slug])

		@name = @selected_schedule.name
		@status = params[:status]
		@psets = Pset.ordered_by_grading #Pset.order(:order)
		@grouped_psets = @psets.group_by &:name

		@users = @selected_schedule.users.not_staff.includes(:group, { submits: [:pset, :grade] }).order("groups.name").order(:name)
		@title = 'List users'

		@active_count = @users.active.count
		@registered_count = @users.registered.count
		@inactive_count = @users.inactive.count
		@done_count = @users.done.count

		case params[:status]
		when 'active'
			@users = @users.active
		when 'registered'
			@users = @users.registered
		when 'inactive'
			@users = @users.inactive
		when 'done'
			@users = @users.done
		end

		@users = @users.group_by(&:group)

		if current_user.assistant?
			render 'overview'
		else
			render 'show'
		end
	end

end
