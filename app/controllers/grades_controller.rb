class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	def show
		@submit = Submit.find(params[:submit_id])
		if @submit
			form
		else
			form
		end
	end
	
	def grade_params
		# params.require(:grade).permit(:comments, :correctness, :design, :grade, :grader, :scope, :style, :done, :subgrades => [])
		params.require(:grade).permit!
	end
	
	def form
		@user = @submit.user
		@pset = @submit.pset
		@grade = @submit.grade || @submit.create_grade({ grader: current_user.login_id })
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @user.id).order('grades.created_at desc')
		@grading_definition = Settings['grading']['grades'][@pset.name] if Settings['grading'] and Settings['grading']['grades']
		render 'form', layout: 'full-width'
	end
	
	def update
		@submit = Submit.find(params[:submit_id])
		if !@submit.grade.done # don't allow done grades to be edited
			@submit.grade.update!(grade_params)
		else
			@submit.grade.update!(params.require(:grade).permit(:done))
			# render nothing: true, status: 403 and return
		end
		redirect_to params[:referer]
	end
	
	def mark_all_done
		@grades = Grade.where(grader:current_user.login_id).where(done:false)
		@grades.update_all(done:true)
		render nothing:true
	end
	
end
