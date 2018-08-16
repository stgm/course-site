class GradesController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_staff
	before_action :require_senior, only: [ :publish_finished ]
	before_action :require_admin, only: [ :publish_mine, :publish_all, :assign_all_final ]

	def show
		@submit = Submit.find(params[:submit_id])
		@submits = Submit.includes(:user, :pset, :grade).where(grades: { status: [nil, Grade.statuses[:open], Grade.statuses[:finished]] }).where(users: { active: true }).order('psets.name')

		if @submit
			if @submit.grade && (@submit.grade.finished? || @submit.grade.published? || @submit.grade.discussed?)
				@grade = @submit.grade
			else
				form
			end
		else
			form
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
	
	# mark grades public that have been marked as "finished" by the grader
	def publish_finished
		schedule = params[:schedule] && Schedule.find(params[:schedule])

		if current_user.head?
			render status: :forbidden and return if not current_user.schedules.include?(schedule)
		end

		grades = schedule && schedule.grades.finished || Grade.finished
		grades.each &:published!
		redirect_to :back
	end
	
	# mark only my own grades public, and even when not marked as finished
	def publish_mine
		schedule = params[:schedule] && Schedule.find(params[:schedule])
		grades = schedule && schedule.grades.where(grader: current_user) || Grade.where(grader: current_user)
		grades.each &:published!
		redirect_to :back
	end

	# try to make all grades public, but only valid grades
	def publish_all
		schedule = params[:schedule] && Schedule.find(params[:schedule])
		grades = schedule && schedule.grades.where.not(status: Grade.statuses[:published]) || Grade.where.not(status: Grade.statuses[:published])
		grades.each &:published!
		redirect_to :back
	end

	def assign_all_final
		schedule = params[:schedule] && Schedule.find(params[:schedule])
		users = schedule && schedule.users

		users.each do |u|
			u.assign_final_grade(@current_user)
		end
		redirect_to :back
	end
	
	def finish_done
		@grades = Grade.where("grade is not null or calculated_grade is not null").joins(:user).open.where(users: { active: true }).where(grader: current_user)
		@grades.update_all(status: Grade.statuses[:finished])
		redirect_to :back
	end
	
	def reopen
		@group = Group.find(params[:group_id])
		@group.grades.finished.update_all(:status => Grade.statuses[:open])
		redirect_to :back
	end
	
	private
	
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
	
end
