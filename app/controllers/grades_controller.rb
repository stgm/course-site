class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	def form
		@user = User.find(params[:user_id])
		@pset = Pset.find(params[:pset_id])
		@submit = Submit.where(pset_id: params[:pset_id], user_id: params[:user_id]).first
		@grade = (@submit && @submit.grade) || Grade.new
		@grades = Grade.includes(:submit).where('submits.user_id = ?', @user.id)
	end
	
	def save
		@submit = Submit.where(pset_id: params[:pset_id], user_id: params[:user_id]).first_or_create
		if @submit.grade
			@submit.grade.update_attributes(params[:grade])
		else
			@submit.create_grade(params[:grade])
			@submit.grade.update_attribute(:grader, current_user.uvanetid)
		end
		redirect_to params[:referer]
	end

end
