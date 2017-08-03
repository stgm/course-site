class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_staff

	def show
		@submit = Submit.find(params[:submit_id])
		if @submit
			if @submit.grade && @submit.grade.published?
				@grade = @submit.grade
			else
				form
			end
		else
			form
		end
	end
	
	def grade_params
		params.require(:grade).permit!
	end
	
	def form
		@user = @submit.user
		@pset = @submit.pset
		@grade = @submit.grade || @submit.build_grade({ grader: current_user })
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @user.id).order('submits.created_at desc')
		@grading_definition = Settings['grading']['grades'][@pset.name] if Settings['grading'] and Settings['grading']['grades']
		render 'form', layout: 'full-width'
	end
	
	def update
		@submit = Submit.find(params[:submit_id])
		if !@submit.grade
			# grades can be created (for a given submit) by anyone
			@submit.build_grade(grader: current_user)
			@submit.grade.update_attributes(grade_params)
		elsif current_user.admin? || @submit.grade.open?
			# grades can only be edited if "open" or if user is admin
			@submit.grade.update!(grade_params)
		end
		redirect_to params[:referer] || :back
	end
	
end
