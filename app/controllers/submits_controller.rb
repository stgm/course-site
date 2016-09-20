class SubmitsController < ApplicationController

	#
	# This controller mainly controls the list of submits to be graded by assistants
	#

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	def index
		if current_user.group
			@to_grade = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).where("users.group_id" => current_user.group.id).where(users: { active: true }).order('psets.name')
			@to_discuss = Submit.includes(:user, :pset, :grade).where(grades: { status: Grade.statuses[:published] }).where("users.group_id" => current_user.group.id).where(users: { active: true }).order('psets.name')
		end
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
