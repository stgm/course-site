class StudentsController < ApplicationController

	before_action CASClient::Frameworks::Rails::Filter
	before_action :require_admin, except: [ :index, :find ]
	before_action :require_senior, only: [ :index, :find ]
	before_action :require_senior, only: [ :publish_finished ]
	before_action :require_admin, only: [ :publish_mine, :publish_all, :assign_all_final ]
	before_action :load_stats, except: :index

	layout 'full-width'

	def index
		@name = params[:group]
		@status = params[:status]

		# check which schedules this user is allowed to view
		if current_user.head?
			@schedules = current_user.schedules
			@current_schedule = params[:group] && Schedule.find_by_name(params[:group]) || current_user.schedules.first
			@current_schedule_id = @current_schedule && @current_schedule.id
			redirect_to({ group: @current_schedule.name }) and return if params[:group].blank?
			render ({ text:"Forbidden", status:403 }) and return if not @schedules.include?(@current_schedule)
			load_stats
		elsif current_user.admin?
			@schedules = Schedule.all
			@current_schedule = params[:group] && Schedule.find_by_name(params[:group]) || Schedule.first
			@current_schedule_id = @current_schedule && @current_schedule.id
			redirect_to({ group: @current_schedule.name }) and return if params[:group].blank?
			load_stats
		end
		
		@psets = Pset.order(:order)
		# @users = User.student.active.where({ schedule: @current_schedule }).includes([:group, { :submits => :grade }]).order("groups.name").order(:name)
		@users = @current_schedule.users.not_staff.includes(:group).order("groups.name").order(:name)
		# @users = @current_schedule.users.not_staff.includes([:group, { :submits => :grade }]).order("groups.name").order(:name)
		
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
	end
	
	def find
		@results = User.student.where("name like ?", "%#{params[:text]}%").limit(10).order(:name)
		respond_to do |format|
			format.js { render 'find' }
		end
	end
	
	# who is inactive but still registered for some schedule earlier?
	def list_inactive
		@name = "Inactive"
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
	
	
	# mark grades public that have been marked as "finished" by the grader
	def publish_finished
		schedule = params[:schedule] && Schedule.find(params[:schedule])

		if current_user.head?
			render status: :forbidden and return if not current_user.schedules.include?(schedule)
		end

		grades = schedule && schedule.grades.finished || Grade.finished
		grades.each &:published!
		redirect_to :back
	end
	
	# mark only my own grades public, and even when not marked as finished
	def publish_mine
		schedule = params[:schedule] && Schedule.find(params[:schedule])
		grades = schedule && schedule.grades.where(grader: current_user) || Grade.where(grader: current_user)
		grades.each &:published!
		redirect_to :back
	end

	# try to make all grades public, but only valid grades
	def publish_all
		schedule = params[:schedule] && Schedule.find(params[:schedule])
		grades = schedule && schedule.grades.where.not(status: Grade.statuses[:published]) || Grade.where.not(status: Grade.statuses[:published])
		grades.each &:published!
		redirect_to :back
	end

	def assign_all_final
		schedule = params[:schedule] && Schedule.find(params[:schedule])
		users = schedule && schedule.users

		users.each do |u|
			u.assign_final_grade(@current_user)
		end
		redirect_to :back
	end
	
	def reopen
		@group = Group.find(params[:group_id])
		@group.grades.finished.update_all(:status => Grade.statuses[:open])
		redirect_to :back
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
