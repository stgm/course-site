class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_staff
	
	# TODO require empty grade, admin or it's my grade
	
	layout false

	def show
		@grade = Grade.find(params[:id])
		@user = @grade.user
		@pset = @grade.pset
		@submit = @grade.submit
		# @grade = @submit.grade || @submit.build_grade({ grader: current_user })
		# @grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @user.id).order('submits.created_at desc')
		@grading_definition = Settings['grading']['grades'][@pset.name] if Settings['grading'] and Settings['grading']['grades']

		if @submit.grade && (@submit.grade.finished? || @submit.grade.published? || @submit.grade.discussed?)
			
		else
			render '_form'
		end
	end
	
	def update
		@submit = Submit.find(params[:submit_id])

		if !@submit.grade
			# grades can be created (for a given submit) by anyone
			@submit.build_grade(grader: current_user)
			@submit.grade.update_attributes(grade_params)
		elsif current_user.senior? || @submit.grade.open?
			# grades can only be edited if "open" or if user is admin
			@submit.grade.update!(grade_params)
		elsif current_user.assistant? && @submit.grade.published? && params["grade"]["status"] == "discussed"
			@submit.grade.update!(grade_params)
		end

		redirect_to params[:referer] || :back
	end
	
	def reopen
		@group = Group.find(params[:group_id])
		@group.grades.finished.update_all(:status => Grade.statuses[:open])
		redirect_to :back
	end
	
	def templatize
		auto_feedback = Settings["course"]["feedback_templates"][params[:type]]
		submit = Submit.find(params[:id])
		@grade = submit.grade || submit.build_grade(grader: current_user)
		@grade.comments = auto_feedback["feedback"]
		@grade.grade = auto_feedback["grade"]
		@grade.status = Grade.statuses[:finished]
		@grade.save
		redirect_to :back
	end
	
	# mark grades public that have been marked as "finished" by the grader
	def publish_finished
		schedule = Schedule.find(params[:schedule])

		if current_user.head?
			render status: :forbidden and return if not current_user.schedules.include?(schedule)
		end

		grades = schedule && schedule.grades.finished || Grade.finished
		grades.each &:published!
		redirect_to :back
	end
	
	# mark only my own grades public, and even when not marked as finished
	def publish_mine
		schedule = Schedule.find(params[:schedule])
		grades = schedule && schedule.grades.where(grader: current_user) || Grade.where(grader: current_user)
		grades.each &:published!
		redirect_to :back
	end

	# try to make all grades public, but only valid grades
	def publish_all
		schedule = Schedule.find(params[:schedule])
		grades = schedule && schedule.grades.where.not(status: Grade.statuses[:published]) || Grade.where.not(status: Grade.statuses[:published])
		grades.each &:published!
		redirect_to :back
	end
	
	private
	
	def grade_params
		params.require(:grade).permit!
	end
	
end
