class GradingController < ApplicationController

	#
	# Manages the list of submits to be graded by assistants
	# -all staff needs access, but the grading list is filled according to assigned groups
	#

	before_action :authorize
	before_action :require_staff

	before_action :load_grading_list, only: [ :index, :show ]
	
	layout "full-width"

	# GET /grading
	def index
		# immediately redirect to first thing that might be graded
		if g = @to_grade.first
			redirect_to grading_path(g, params.permit(:pset, :group, :status))
		else
			redirect_back fallback_location: '/', alert: "There's nothing to grade from your grading groups yet!"
		end
	end
	
	# GET /grading/:submit_id
	def show
		# load the submit and any grade that might be attached
		@submit = Submit.includes(:grade, :user, :pset).find(params[:submit_id])
		@grade = @submit.grade || @submit.build_grade({ grader: current_user })

		# load files submitted in child psets if we want to grade a parent module
		@files_from_module = @submit.user.files_for_module(@submit.pset.mod) if @submit.pset.mod

		# either use the files attached to this specific submit, or all gathered from the module
		@files = @submit.file_contents || @files_from_module

		# load other grades for summarizing
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @submit.user.id).order('submits.created_at desc')
	end
	
	# GET /grading/:submit_id/download
	def download
		@submit = Submit.find(params[:grading_submit_id])
		@file = @submit.file_contents[params[:filename]]
		send_data @file, type: "text/plain", filename: params[:filename]
	end

	# GET /grading/finish
	def finish
		# allow grader to mark as finished so the grades may be published later
		# TODO some of the constraints can be moved to model
		@grades = Grade.where("grade is not null or calculated_grade is not null").joins(:user).unfinished.where(users: { active: true }).where(grader: current_user)
		@grades.update_all(status: Grade.statuses[:finished])
		redirect_back fallback_location: '/'
	end
	
	private
	
	def load_grading_list
		if !Schedule.exists? #current_user.admin? || !Schedule.exists?
			# admins get everything to be graded (in all schedules and groups)
			@to_grade = Submit.to_grade
		elsif current_user.admin?
			# admins get everything from their current schedule (they can switch schedules)
			@to_grade = Submit.admin_to_grade.where("users.schedule_id" => current_user.schedule)
			if params[:group]
				@to_grade = @to_grade.where(users: { group_id: params[:group] })
			end
			if params[:status]
				@to_grade = @to_grade.where(grades: { status: params[:status] })
			end
			if params[:pset]
				@to_grade = @to_grade.where(psets: { id: params[:pset] })
			end
		elsif current_user.head? && current_user.schedules.any?
			# heads get stuff from one schedule, but from all groups
			@to_grade = Submit.to_grade.where("users.schedule_id" => current_user.schedules)
			if params[:group]
				@to_grade = @to_grade.where(users: { group_id: params[:group] })
			end
			if params[:status]
				@to_grade = @to_grade.where(grades: { status: params[:status] })
			end
			if params[:pset]
				@to_grade = @to_grade.where(psets: { id: params[:pset] })
			end
		elsif current_user.assistant? && (Group.any? || Schedule.any?) && (current_user.groups.any? || current_user.schedules.any?)
			# other assistants get stuff only from their assigned group
			@to_grade = Submit.to_grade.where(["users.group_id in (?) or users.schedule_id in (?)", current_user.groups.pluck(:id), current_user.schedules.pluck(:id)])
		elsif current_user.assistant? && !(Group.any? || Schedule.any?)
			# assistants get everything if there are no groups or schedules
			# but nothing if there are groups and they haven't been assigned one yet
			@to_grade = Submit.to_grade
		end

		redirect_back(fallback_location: '/', alert: "You haven't been assigned grading groups yet!") if not @to_grade
	end
	
end
