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
	
	def assign_final_grade
		User.find(params[:id]).assign_final_grade
	end
	
	def change_user_name
		User.find(params[:id]).update_attributes(params[:user])
		render json:true
	end

	#
	# list all submits
	#
	def grades_for_group
		if params[:group].present?
			@users = Group.find_by_name(params[:group]).users.includes(:submits => [:pset, :grade]).order(:name)
		else
			if Group.count > 0
				@users = Group.order(:name).first.users.order(:name)
			else
				@users = User.active.no_group.not_admin.order(:name)
			end
		end
		@psets = Pset.order(:order).all
		@groupless_count = User.active.no_group.not_admin.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count
		@title = 'List users'
		render 'grades'
	end
	
	def grades_for_inactive
		@users = User.inactive.not_admin.order(:name)
		@psets = Pset.order(:order)
		@groupless_count = User.active.no_group.not_admin.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count
		@title = 'List users'
		render 'grades'
	end
	
	def grades_for_other
		@users = User.active.no_group.not_admin.order(:name)
		@psets = Pset.order(:order)
		@groupless_count = User.active.no_group.not_admin.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count
		@title = 'List users'
		render 'grades'
	end
	
	def grades_for_admins
		@users = User.admin.order(:name)
		@psets = Pset.order(:order)
		@groupless_count = User.active.no_group.not_admin.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count
		@title = 'List users'
		render 'grades'
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
