class SubmitsController < ApplicationController

	#
	# This controller mainly controls the list of submits to be graded by assistants
	#

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_staff

	def index
		if current_user.admin?
			# admins get everything to be graded (in all schedules and groups)
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).order('psets.name')
		elsif Schedule.any? and current_user.head?
			# heads get stuff from one schedule, but from all groups
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).where("users.schedule_id" => current_user.schedule.id).order('psets.name')
		elsif Group.any? and current_user.group
			# other assistants get stuff only from their assigned group
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).where("users.group_id" => current_user.group.id).where(users: { active: true }).order('psets.name')
		elsif !Group.any? and !Schedule.any?
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
		elsif Schedule.any? and current_user.head?
			# heads get stuff from one schedule, but from all groups
			@to_discuss = Submit.includes(:user, :pset, :grade).where('submits.submitted_at is not null').where(grades: { status: Grade.statuses[:published] }).where("users.schedule_id" => current_user.schedule.id).order('psets.name, grades.grader_id')
		elsif Group.any? and current_user.group
			# other assistants get stuff only from their assigned group
			@to_discuss = Submit.includes(:user, :pset, :grade).where('submits.submitted_at is not null').where(grades: { status: Grade.statuses[:published] }).where("users.schedule_id" => current_user.schedule.id).order('psets.name, grades.grader_id')
		elsif !Group.any? and !Schedule.any?
			# assistants get everything if there are no groups or schedules
			@to_discuss = Submit.includes(:user, :pset, :grade).where('submits.submitted_at is not null').where(grades: { status: Grade.statuses[:published] }).where(users: { active: true }).order('psets.name')
		end
		
		redirect_back_with("You do not have permission to grade.") if not @to_discuss
		
		@groups = Group.all
		@psets = Pset.all
	end
	
	def create
		submit = Submit.create(params.require(:submit).permit(:pset_id, :user_id))
		redirect_to submit_grade_path(submit_id: submit.id)
	end

	def destroy
		@submit = Submit.find(params[:id])
		@submit.destroy
		redirect_to params[:referer]
	end	
	
	def mark_all_done
		@grades = Grade.where("grade is not null or calculated_grade is not null").joins(:user).open.where(users: { active: true }).where(grader: current_user)
		@grades.update_all(status: Grade.statuses[:finished])
		redirect_to :back
	end
	
end
