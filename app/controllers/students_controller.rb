class StudentsController < ApplicationController

	before_action CASClient::Frameworks::Rails::Filter
	before_action :require_admin, except: [ :index ]
	before_action :require_senior, only: [ :index ]
	before_action :load_stats, except: :index

	layout 'full-width'

	def index
		if current_user.head?
			@schedules = current_user.schedules
			@current_schedule = params[:group] && Schedule.find_by_name(params[:group]) || current_user.schedules.first
			@current_schedule_id = @current_schedule && @current_schedule.id
			render text: "Uhhh" if not @schedules.include?(@current_schedule)
			load_stats
		elsif current_user.admin?
			@schedules = Schedule.all
			@current_schedule = params[:group] && Schedule.find_by_name(params[:group]) || Schedule.first
			@current_schedule_id = @current_schedule && @current_schedule.id
			logger.debug "IDIDIDIDIDID"
			logger.debug @current_schedule
			logger.debug @current_schedule_id
			load_stats
		end
		
		@psets = Pset.order(:order)
		@users = User.student.active.where({ schedule: @current_schedule }).includes([:group, { :submits => :grade }]).order("groups.name").order(:name)
		@users = @users.group_by(&:group)
		
		@all = User.where({ schedule: @current_schedule })
		@assist = @all.staff
		@not_started = @all.student.not_started
		@stagnated = @all.student.stagnated
		@inactive = @all.student.inactive
		@done = @all.student.done
	end
	
	def statuses
		@current_schedule = params[:group] && Schedule.find_by_name(params[:group])
		@users = User.student.where({ schedule: @current_schedule }).includes(:hands).order(:name)
		
	end
	
	# who is inactive but still registered for some schedule earlier?
	def list_inactive
		@psets = Pset.order(:order)
		@schedules = Schedule.all
		if @schedules.any?
			@users = User.inactive.student.where("schedule_id is not null").order(:name).group_by(&:schedule)
		else
			@users = User.inactive.student.where("schedule_id is not null").order(:name).group_by(&:group)
		end
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	# who didn't even start etc?
	def list_other
		@psets = Pset.order(:order)
		@schedules = Schedule.all
		@users = User.where('schedule_id' => nil).student.order(:name).group_by(&:group)
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	def list_admins
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
