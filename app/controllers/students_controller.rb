class StudentsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	before_action :load_stats
	layout 'full-width'

	def index
		@schedules = Schedule.all
		@current_schedule = params[:group] && Schedule.find_by_name(params[:group]) || Schedule.first
		@users = User.not_admin_or_assistant.where({ schedule: @current_schedule }).includes(:group).order("groups.name").order(:name)
		#todo if no schedule, do inactive/active
		@submits = Submit.includes(:grade).group_by(&:user_id)
		@users = @users.group_by(&:group)
	end
	
	def list_inactive
		@schedules = Schedule.all
		@users = User.where('schedule_id' => nil).not_admin_or_assistant.order(:name).group_by(&:group)
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	def list_admins
		@schedules = Schedule.all
		@users = User.admin_or_assistant.order(:name).group_by(&:group)
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	def show
		@student = User.includes(:hands).find(params[:id])
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @student.id).order('grades.created_at desc')
		@groups = Group.order(:name)
		render layout: 'application'
	end
	
	def mark_all_public
		@grades = Grade.joins(:user).finished.where(users: { active: true })
		@grades.update_all(status: Grade.statuses[:published])
		redirect_to :back
	end

	#
	# put submit into grading queue
	#
	def touch_submit
		s = Submit.find(params[:submit_id])
		s.grade.open! if s.grade
		redirect_to :back
	end

	def assign_final_grade
		User.all.each do |u|
			u.assign_final_grade(@current_user)
		end
		redirect_to :back
	end
	
	private
	
	def load_stats
		@active_count = User.active.not_admin_or_assistant.count
		@inactive_count = User.inactive.not_admin_or_assistant.count
		@admin_count = User.admin_or_assistant.count
		@psets = Pset.order(:order)
		@title = 'List users'
	end

end
