class SubmitsController < ApplicationController

	#
	# This controller mainly controls the list of submits to be graded by assistants
	#

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_staff
	before_filter :require_senior, only: [ :form_for_late, :close_and_mail_late, :form_for_missing, :notify_missing ]

	def index
		if current_user.admin? or !Schedule.exists?
			# admins get everything to be graded (in all schedules and groups)
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).order('psets.name')
		elsif current_user.head? and current_user.schedules.any?
			# heads get stuff from one schedule, but from all groups
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).where("users.schedule_id" => current_user.schedules).order('psets.name')
		elsif current_user.assistant? and (current_user.groups.any? or current_user.schedules.any?)
			# other assistants get stuff only from their assigned group
			@to_grade = Submit.includes(:user, :pset, :grade).where(["users.group_id in (?) or users.schedule_id in (?)", current_user.groups.pluck(:id), current_user.schedules.pluck(:id)]).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).order('psets.name')
		elsif current_user.assistant?
			# assistants get everything if there are no groups or schedules
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).where(users: { active: true }).order('psets.name')
		end
		
		redirect_back_with("You do not have permission to grade.") if not @to_grade
		
		@groups = Group.all
		@psets = Pset.all
	end
	
	def discuss
		if current_user.admin?
			# admins get everything to be discussed (in all schedules and groups)
			@to_discuss = Submit.includes(:user, :pset, :grade).where('submits.submitted_at is not null').where(grades: { status: Grade.statuses[:published] }).order('psets.name, grades.grader_id')
		elsif current_user.head? and current_user.schedules.any?
			# heads get stuff from one schedule, but from all groups
			@to_discuss = Submit.includes(:user, :pset, :grade).where('submits.submitted_at is not null').where(grades: { status: Grade.statuses[:published] }).where("users.schedule_id" => current_user.schedule.id).order('psets.name, grades.grader_id')
		elsif current_user.assistant? and (current_user.groups.any? or current_user.schedules.any?)
			# other assistants get stuff only from their assigned group
			@to_discuss = Submit.includes(:user, :pset, :grade).where('submits.submitted_at is not null').where(grades: { status: Grade.statuses[:published] }).where(["users.group_id in (?) or users.schedule_id in (?)", current_user.groups.pluck(:id), current_user.schedules.pluck(:id)]).order('psets.name, grades.grader_id')
		elsif current_user.assist?
			# assistants get everything if there are no groups or schedules
			@to_discuss = Submit.includes(:user, :pset, :grade).where('submits.submitted_at is not null').where(grades: { status: Grade.statuses[:published] }).where(users: { active: true }).order('psets.name')
		end
		
		redirect_back_with("You do not have permission to grade.") if not @to_discuss
		
		@groups = Group.all
		@psets = Pset.all
	end
	
	def create
		submit = Submit.create(params.require(:submit).permit(:pset_id, :user_id))
		redirect_to submit_grade_path(submit_id: submit.id, referer: request.referer)
	end

	def destroy
		@submit = Submit.find(params[:id])
		@submit.destroy
		redirect_to params[:referer]
	end	
	
	def form_for_late
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
		redirect_to({ action: "index" }, notice: 'E-mails are being sent.')
	end
	
	def form_for_missing
		@schedules = Schedule.all
		@psets = Pset.all
		render layout: "application"
	end
	
	def notify_missing
		@schedule = Schedule.find(params[:schedule_id])
		@pset = Pset.find(params[:pset_id])
		
		@schedule.users.not_staff.each do |u|
			if !@pset.submit_from(u)
				NonSubmitMailer.new_mail(u, @pset, params[:text]).deliver
			end
		end
		redirect_to({ action: "index" }, notice: 'E-mails are being sent.')
	end
	
end
