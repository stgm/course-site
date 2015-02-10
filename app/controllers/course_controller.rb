require 'course'

class CourseController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	#
	# update the courseware from the linked git repository
	#
	def import
		Course.reload
		redirect_to :back, notice: 'The course content was successfully updated.'
	end
	
	def add_student
		Track.find(params[:track_id]).users << User.where(uvanetid:params[:student_id]).first_or_create
		render nothing: true, status: 200
	end
	
	def remove_student
		Track.find(params[:track_id]).users.delete(User.where(uvanetid:params[:student_id]))
		logger.debug Track.find(params[:track_id]).users.inspect
		logger.debug User.where(uvanetid:params[:student_id]).inspect
		redirect_to :back
	end
	
	def change_user_name
		User.find(params[:id]).update_attributes(params[:user])
		render json:true
	end

	#
	# list all submits
	#
	def grades
		# if tracks have NOT been defined in course.yml
		@users = User
		@users = @users.active if !params[:active]
		@groupless = @users.no_group.not_admin.order(:name)
		@admins = User.admin.order(:name)
		@psets = Pset.order(:order)
		@title = 'List users'
		render 'grades_groups', layout:'full_width'
	end
	
	def toggle_public_grades
		Settings.public_grades = !Settings.public_grades
		redirect_to :back
	end
	
	def toggle_grading_allowed
		Settings.allow_grading = !Settings.allow_grading
		redirect_to :back
	end
	
	def toggle_send_grade_mails
		Settings.send_grade_mails = !Settings.send_grade_mails
		redirect_to :back
	end
	
	#
	# update submit date for single submit, in order to get it into the queue again
	#
	def touch_submit
		Submit.find(params[:submit_id]).update_attribute(:submitted_at, Time.now)
		redirect_to :back
	end
	
end
