class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant
	
	include GradesHelper

	def grade_params
		# params.require(:grade).permit(:comments, :correctness, :design, :grade, :grader, :scope, :style, :done, :subgrades => [])
		params.require(:grade).permit!
	end
	
	def form
		@user = User.find(params[:user_id])
		@pset = Pset.find(params[:pset_id])
		@submit = Submit.where(pset_id: params[:pset_id], user_id: params[:user_id]).first
		@grade = (@submit && @submit.grade) || Grade.new
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @user.id).order('grades.created_at desc')
		@grading_definition = Settings['grading']['grades'][@pset.name]
		render layout: 'full-width'
	end
	
	def save
		@submit = Submit.where(pset_id: params[:pset_id], user_id: params[:user_id]).first_or_create
		if @submit.grade
			if current_user.is_admin? || !@submit.grade.done
				logger.info grade_params
				@submit.grade.update!(grade_params)
			else
				render nothing: true, status: 403
			end
		else
			@submit.create_grade
			@submit.grade.update!(grade_params)
			@submit.grade.update!(grader: current_user.login_id)
		end
		redirect_to params[:referer]
	end
	
	def destroy
		@submit = Submit.find(params[:submit_id])
		@submit.grade.destroy if @submit.grade
		@submit.destroy
		redirect_to params[:referer]
	end
	
	def mark_all_done
		@grades = Grade.where(grader:current_user.login_id).where(done:false)
		@grades.update_all(done:true)
		render nothing:true
	end
	
end
