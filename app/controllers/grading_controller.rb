class GradingController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant, :grading_allowed

	# 
	# List of problems to be graded by assistants
	#
	def index
		@submits = Submit.includes(:user, :pset, :grade).where("grades.updated_at < submits.updated_at or grades.updated_at is null or grades.updated_at > ?", 1.days.ago)
		@submits = @submits.where(pset_id:params[:pset]) if not params[:pset].blank?
		@submits = @submits.where("users.group_id" => params[:group]) if not params[:group].blank?
		@submits = @submits.order('psets.name')
		@groups = Group.all
		@psets = Pset.all
	end
	
	private
	
	def grading_allowed
		render text: "Grading is currently closed." unless Settings.allow_grading
	end

end
