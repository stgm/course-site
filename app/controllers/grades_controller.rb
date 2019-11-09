class GradesController < ApplicationController

	before_action CASClient::Frameworks::Rails::Filter
	before_action :require_admin, except: [:update, :templatize]
	before_action :require_staff, only: [:update, :templatize]
	
	# TODO require empty grade, admin or it's my grade
	
	layout false

	def show
		@grade = Grade.find(params[:id])
		@user = @grade.user
		@pset = @grade.pset
		@submit = @grade.submit
		# @automatic_grades = @grade.submit.automatic
		# @grade = @submit.grade || @submit.build_grade({ grader: current_user })
		# @grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @user.id).order('submits.created_at desc')
		@grading_definition = Settings['grading']['grades'][@pset.name] if Settings['grading'] and Settings['grading']['grades']

		if @submit.grade && (@submit.grade.finished? || @submit.grade.public?)
			
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

		redirect_to params[:referer] or redirect_back fallback_location: '/'
	end
	
	def reopen
		@group = Group.find(params[:group_id])
		@group.grades.finished.update_all(:status => Grade.statuses[:open])
		redirect_back(fallback_location: '/')
	end
	
	def templatize
		auto_feedback = Settings["course"]["feedback_templates"][params[:type]]
		submit = Submit.find(params[:id])
		@grade = submit.grade || submit.build_grade(grader: current_user)
		@grade.comments = auto_feedback["feedback"]
		@grade.grade = auto_feedback["grade"]
		@grade.status = Grade.statuses[:finished]
		@grade.save
		redirect_back(fallback_location: '/')
	end
	
	def publish
		pset = Pset.find_by_name(params[:pset])
		schedule = current_user.schedule
		Grade.joins(submit: :user).where("submits.pset_id = ? and users.schedule_id = ?", pset.id, schedule.id).finished.update_all(status: Grade.statuses[:published])
		render text: ""
	end
	
	# mark grades public that have been marked as "finished" by the grader
	def publish_finished
		schedule = params[:schedule] && Schedule.find_by_id(params[:schedule])

		if current_user.head?
			render status: :forbidden and return if not current_user.schedules.include?(schedule)
		end

		grades = schedule && schedule.grades.finished || Grade.finished
		grades.each &:published!
		redirect_back(fallback_location: '/')
	end
	
	# mark only my own grades public, and even when not marked as finished
	def publish_mine
		schedule = params[:schedule] && Schedule.find_by_id(params[:schedule])
		grades = schedule && schedule.grades.where(grader: current_user) || Grade.where(grader: current_user)
		grades.each &:published!
		redirect_back(fallback_location: '/')
	end

	# try to make all grades public, but only valid grades
	def publish_all
		schedule = params[:schedule] && Schedule.find_by_id(params[:schedule])
		grades = schedule && schedule.grades.where.not(status: [Grade.statuses[:published], Grade.statuses[:published], Grade.statuses[:exported]])
		grades.each &:published!
		redirect_back(fallback_location: '/')
	end
	
	def form_for_publish_auto
		@psets = Pset.where(automatic: true).order(:order)
		render layout: "application"
	end

	def publish_auto
		ids = []
		params[:psets].each do |name|
			pset = Pset.find_by_name(name)
			ids << pset.id
		end
		
		@schedule.submits.where(pset_id: ids).each do |s|
			if s.grade.nil?
				g = s.build_grade
				if g.subgrades.correctness == 5
					g.published!
				end
			end
		end
		
		redirect_to students_in_group_path(@schedule.name)
	end
	
	def assign_all_final
		schedule = params[:schedule] && Schedule.find_by_id(params[:schedule])
		users = schedule && schedule.users

		users.each do |u|
			u.assign_final_grade(@current_user)
		end
		redirect_back(fallback_location: '/')
	end
	
	private
	
	def grade_params
		params.require(:grade).permit!
	end
	
end
