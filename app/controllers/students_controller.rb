class StudentsController < ApplicationController

	before_action CASClient::Frameworks::Rails::Filter
	before_action :require_admin, except: [ :index, :show, :mark_all_public ]
	before_action :require_senior, only: [ :index, :show, :mark_all_public ]
	before_action :load_stats, except: :index

	layout 'full-width'

	def index
		if current_user.head?
			@current_schedule = current_user.schedule
		elsif current_user.admin?
			@current_schedule = params[:group] && Schedule.find_by_name(params[:group]) || Schedule.first
			load_stats
		end
		# redirect_to :back, notice: "You don't have a schedule, please ask an admin to assign you." if not @current_schedule
		
		@psets = Pset.order(:order)
		@schedules = Schedule.all
		@users = User.student.where({ schedule: @current_schedule }).includes([:group, { :submits => :grade }]).order("groups.name").order(:name)
		#todo if no schedule, do inactive/active
		# @submits = Submit.where("user_id in (?)", @users).includes(:grade).group_by(&:user_id)
		@users = @users.group_by(&:group)
	end
	
	def list_inactive
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
	
	def mark_all_public
		if current_user.head?
			@grades = current_user.schedule.grades.joins(:user).finished.where(users: { active: true })
		elsif current_user.admin?
			schedule = Schedule.find(params[:schedule])
			@grades = schedule.grades.joins(:user).finished.where(users: { active: true })
		end
		@grades.update(status: Grade.statuses[:published])
		redirect_to :back
	end
	
	def mark_my_public
		schedule = Schedule.find(params[:schedule])
		@grades = schedule.grades.where(grader: current_user)
		@grades.update(status: Grade.statuses[:published])
		redirect_to :back
	end

	def mark_everything_public
		schedule = Schedule.find(params[:schedule])
		schedule.grades.update(status: Grade.statuses[:published])
		redirect_to :back
	end

	def assign_final_grade
		User.all.each do |u|
			u.assign_final_grade(@current_user)
		end
		redirect_to :back
	end
	
	def late_form
		@schedules = Schedule.all
		@psets = Pset.all
		render layout: "application"
	end
	
	def close_and_mail_late
		@schedule = Schedule.find(params[:schedule_id])
		@pset = Pset.find(params[:pset_id])
		
		@schedule.users.not_staff.each do |u|
			if !@pset.submit_from(u)
				s = Submit.create user: u, pset: @pset
				s.create_grade grader: current_user, comments: params[:text]
				s.grade.update(grade: 0, status: Grade.statuses[:finished])
			end
		end
		redirect_to action: "index"
	end
	
	private
	
	def load_stats
		@active_count = User.active.student.count
		@inactive_count = User.student.where(schedule_id: nil).count
		   #User.inactive.student.count
		@admin_count = User.staff.count
		@schedule_count = User.student.group(:schedule_id).count
		@title = 'List users'
	end

end
