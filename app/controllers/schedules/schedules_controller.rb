class Schedules::SchedulesController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_staff
	before_action :load_schedule # needed to verify access
	before_action :verify_access

	layout 'schedules'

	def index

		# check which schedules this user is allowed to view
		if current_user.assistant?
			@accessible_schedules = current_user.groups
			@selected_schedule = Group.friendly.find(params[:schedule_slug])

			# [["Problems", ["M1", "M2", "M3", ...]], ...]
			@overview = Settings.grading.select { |c,v| v['show_progress'] }.map { |c,v| [c, v['submits'].map {|k,v| k}] }
		elsif current_user.head? || current_user.admin?
			@accessible_schedules = current_user.accessible_schedules
			@selected_schedule = Schedule.friendly.find(params[:schedule_slug])
		end
		
		@name = @selected_schedule.name
		@status = params[:status]
		@psets = Pset.order(:order)
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
		
		@groups = @users.group_by(&:group)
		
		if current_user.assistant?
			render 'overview'
		else
			render 'show'
		end
	end

	#
	# set "current" schedule that is displayed to users
	#
	def set_current_module
		if params[:item] == "0"
			@schedule.update_attribute(:current, nil)
		else
			@schedule.update_attribute(:current, ScheduleSpan.find(params[:item]))
		end
		render json: nil
	end

end
