class SubmitsController < ApplicationController

	#
	# This controller manages the list of submits to be graded by assistants
	#

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_staff
	
	before_action :load_grading_list, only: [ :index, :show ]
	
	layout "full-width"

	def index
		# immediately redirect to first thing that might be graded
		if g = @to_grade.first
			redirect_to submit_path(g, params.slice(:pset, :group, :status))
		else
			redirect_back_with("There's nothing to grade from your grading groups yet!")
		end
	end
	
	def show
		# load the submit and any grade that might be attached
		@submit = Submit.find(params[:id])
		@automatic_grades = @submit.automatic
		@grade = @submit.grade || @submit.build_grade({ grader: current_user })

		# load other useful stuff
		@user = @submit.user
		@pset = @submit.pset
		if mod = @pset.parent_mod
			@files_from_module = Submit.where(pset: mod.psets, user: @user).pluck(:file_contents).compact
			if @files_from_module.present?
				@files_from_module = @files_from_module.reduce(Hash.new, :merge)
			end
		end
		@files = @submit.file_contents || @files_from_module
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @user.id).order('submits.created_at desc')
		@grading_definition = Settings['grading']['grades'][@pset.name] if Settings['grading'] and Settings['grading']['grades']
	end
	
	def create
		s = Submit.create(params[:submit].permit([:pset_id, :user_id]))
		redirect_to submit_path(s.id)
	end
	
	def destroy
		@submit = Submit.find(params[:id])
		@submit.destroy
		redirect_to submits_path
	end
	
	def finish
		# allow grader to mark as finished so the grades may be published later
		# TODO some of the constraints can be moved to model
		@grades = Grade.where("grade is not null or calculated_grade is not null").joins(:user).open.where(users: { active: true }).where(grader: current_user)
		@grades.update_all(status: Grade.statuses[:finished])
		redirect_to :back
	end
	
	def download
		@submit = Submit.find(params[:id])
		@file = @submit.file_contents[params[:filename]]
		send_data @file, type: "text/plain", filename: params[:filename]
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

		redirect_back_with("You haven't been assigned grading groups yet!") if not @to_grade
	end

	#
	# This controller mainly controls the list of submits to be graded by assistants
	#

	# before_filter CASClient::Frameworks::Rails::Filter
	# before_filter :require_staff
	# before_filter :require_senior, only: [ :form_for_late, :close_and_mail_late, :form_for_missing, :notify_missing ]
	#
	# def create
	# 	submit = Submit.create(params.require(:submit).permit(:pset_id, :user_id))
	# 	redirect_to submit_grade_path(submit_id: submit.id, referer: request.referer)
	# end
	#
	# def destroy
	# 	@submit = Submit.find(params[:id])
	# 	@submit.destroy
	# 	redirect_to params[:referer]
	# end
	#
	# def form_for_late
	# 	@schedules = Schedule.all
	# 	@psets = Pset.all
	# 	render layout: "application"
	# end
	#
	# def close_and_mail_late
	# 	@schedule = Schedule.find(params[:schedule_id])
	# 	@pset = Pset.find(params[:pset_id])
	#
	# 	@schedule.users.not_staff.each do |u|
	# 		if !@pset.submit_from(u)
	# 			s = Submit.create user: u, pset: @pset
	# 			s.create_grade grader: current_user, comments: params[:text]
	# 			s.grade.update(grade: 0, status: Grade.statuses[:finished])
	# 		end
	# 	end
	# 	redirect_to({ action: "index" }, notice: 'E-mails are being sent.')
	# end
	#
	# def form_for_missing
	# 	@schedules = Schedule.all
	# 	@psets = Pset.all
	# 	render layout: "application"
	# end
	#
	# def notify_missing
	# 	@schedule = Schedule.find(params[:schedule_id])
	# 	@pset = Pset.find(params[:pset_id])
	#
	# 	@schedule.users.not_staff.each do |u|
	# 		if !@pset.submit_from(u)
	# 			NonSubmitMailer.new_mail(u, @pset, params[:text]).deliver
	# 		end
	# 	end
	# 	redirect_to({ action: "index" }, notice: 'E-mails are being sent.')
	# end
	
end
