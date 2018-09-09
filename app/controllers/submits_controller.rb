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
			redirect_to submit_path(g)
		else
			redirect_back_with("There's nothing to grade from your grading groups yet!")
		end
	end
	
	def show
		# load the submit and any grade that might be attached
		@submit = Submit.find(params[:id])
		@grade = @submit.grade || @submit.build_grade({ grader: current_user })

		# load other useful stuff
		@user = @submit.user
		@pset = @submit.pset
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @user.id).order('submits.created_at desc')
		@grading_definition = Settings['grading']['grades'][@pset.name] if Settings['grading'] and Settings['grading']['grades']
	end
	
	def create
		s = Submit.create(params[:submit]).permit([:pset_id, :user_id])
		redirect_to submits_path(submit_id: s.id)
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
	
	private
	
	def load_grading_list
		if current_user.admin? or !Schedule.exists?
			# admins get everything to be graded (in all schedules and groups)
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).order('psets.name')
		elsif current_user.head? and current_user.schedules.any?
			# heads get stuff from one schedule, but from all groups
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).where("users.schedule_id" => current_user.schedules).order('psets.name')
		elsif current_user.assistant? and (current_user.groups.any? or current_user.schedules.any?)
			# TODO is this correct??? the and/or in the line above
			# other assistants get stuff only from their assigned group
			@to_grade = Submit.includes(:user, :pset, :grade).where(["users.group_id in (?) or users.schedule_id in (?)", current_user.groups.pluck(:id), current_user.schedules.pluck(:id)]).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).order('psets.name')
		elsif current_user.assistant?
			# assistants get everything if there are no groups or schedules
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).where(users: { active: true }).order('psets.name')
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
