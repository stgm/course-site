class StudentsController < ApplicationController

	before_action :authorize
	before_action :require_admin, except: [ :index, :find ]
	before_action :require_staff, only: [ :index, :find ]
	before_action :load_stats, except: :index

	layout 'full-width'

	def index
		@name = params[:group]
		@status = params[:status]

		# check which schedules this user is allowed to view
		if current_user.assistant?
			# heads need to have schedules assigned to them
			redirect_back(fallback_location: '/', alert: "You haven't been assigned a schedule!") and return if current_user.groups.empty?
			@schedules = current_user.groups
			@current_schedule = params[:group] && Group.find_by_name(params[:group]) || current_user.groups.first
			@current_schedule_id = @current_schedule && @current_schedule.id
			if @current_schedule
				redirect_to({ group: @current_schedule.name }) and return if params[:group].blank?
				render ({ text:"Forbidden", status:403 }) and return if not @schedules.include?(@current_schedule)
			end
			# [["Problems", ["M1", "M2", "M3", ...]], ...]
			@overview = Settings.grading.select { |c,v| v['show_progress'] }.map { |c,v| [c, v['submits'].map {|k,v| k}] }
			load_stats
		elsif current_user.head?
			# heads need to have schedules assigned to them
			redirect_back(fallback_location: '/', alert: "You haven't been assigned a schedule!") and return if current_user.schedules.empty?
			@schedules = current_user.schedules
			@current_schedule = params[:group] && Schedule.find_by_name(params[:group]) || current_user.schedules.first
			@current_schedule_id = @current_schedule && @current_schedule.id
			if @current_schedule
				redirect_to({ group: @current_schedule.name }) and return if params[:group].blank?
				render ({ text:"Forbidden", status:403 }) and return if not @schedules.include?(@current_schedule)
			end
			load_stats
		elsif current_user.admin?
			@schedules = Schedule.all
			@current_schedule = params[:group] && Schedule.find_by_name(params[:group]) || Schedule.first
			@current_schedule_id = @current_schedule && @current_schedule.id
			if @current_schedule
				redirect_to({ group: @current_schedule.name }) and return if params[:group].blank?
			end
			load_stats
		end
		
		@psets = Pset.order(:order)
		@grouped_psets = @psets.group_by &:name
		if @current_schedule
			@users = @current_schedule.users.not_staff.includes(:group, { submits: [:pset, :grade] }).order("groups.name").order(:name)
		else
			@users = User.not_staff.includes(:group, { submits: [:pset, :grade] }).order("groups.name").order(:name)
		end
		
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
			render 'index'
		end
	end
	
	# GET /students/find?text=.. for admins + heads
	def find
		if params[:text] != ""
			@results = User.joins(:logins).student.where("users.name like ? or logins.login like ?", "%#{params[:text]}%", "%#{params[:text]}%").limit(10).order(:name)
		else
			@results = []
		end
		
		respond_to do |format|
			format.js { render 'find' }
		end
	end
	
	# who is inactive but still registered for some schedule earlier?
	def list_inactive
		@name = "Inactive"
		@psets = Pset.order(:order)
		@schedules = Schedule.all
		if @schedules.present?
			@users = User.inactive.student.where("schedule_id is not null").order(:name).group_by(&:schedule)
		else
			@users = User.inactive.student.where("schedule_id is not null").order(:name).group_by(&:group)
		end
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	# who didn't even start etc?
	def list_other
		@name = "Other"
		@psets = Pset.order(:order)
		@schedules = Schedule.all
		@users = User.where('schedule_id' => nil).student.order(:name).group_by(&:group)
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	def list_admins
		@name = "Admins"
		@psets = Pset.order(:order)
		@schedules = Schedule.all
		@users = User.staff.order(:name).group_by(&:group)
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	private
	
	def load_stats
		@active_count = User.active.student.count
		@inactive_count = User.student.inactive.where("schedule_id is not null").count
		@other_count =  User.student.where(schedule_id: nil).count
		@admin_count = User.staff.count
		@schedule_count = User.student.active.group(:schedule_id).count
		@title = 'List users'
	end

end
