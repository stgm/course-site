class SubmitsController < ApplicationController

	#
	# This controller mainly controls the list of submits to be graded by assistants
	#

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	def index
		if current_user.is_admin?
			@submits = Submit.includes(:user, :pset, :grade)
		else
			@submits = Submit.includes(:user, :pset, :grade).where("submits.submitted_at > grades.updated_at or grades.updated_at is null or grades.public = ?", false)
		end
		@submits = @submits.where(pset_id:params[:pset]) if not params[:pset].blank?
		@submits = @submits.where("users.group_id" => params[:group]) if not params[:group].blank?
		@submits = @submits.order('psets.name')
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
	
end
