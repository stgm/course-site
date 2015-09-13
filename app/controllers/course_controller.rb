require 'course'
require 'course_loader'

class CourseController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	before_action :load_attendance, only: [:grades_for_group, :grades_for_inactive, :grades_for_other, :grades_for_admins]


	def load_attendance
		if !Settings['attendance_last_calced'] || Settings['attendance_last_calced'] < 1.day.ago
			Settings['attendance_last_calced'] = Time.now
			User.all.each do |u|
				user_attendance = []
				for i in 0..6
					d_start = Date.today + 1 - 1 - i # start of tomorrow
					d_end = Date.today + 1 - i # start of today
					hours = u.attendance_records.where("cutoff >= ? and cutoff < ?", d_start, d_end).count
					user_attendance.insert 0, hours
				end
				u.update_attribute(:attendance, user_attendance.join(","))
			end
		end
	end

	#
	# update the courseware from the linked git repository
	#
	def import
		CourseLoader.new.start
		redirect_to :back, notice: 'The course content was successfully updated.'
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
			@users = Group.find_by_name(params[:group]).users.includes(:logins, :submits => [:pset, :grade]).order(:name)
		else
			if Group.count > 0
				@users = Group.order(:name).first.users.includes(:logins, :submits => [:pset, :grade]).order(:name)
			else
				@users = User.active.no_group.not_admin.includes(:logins, :submits => [:pset, :grade]).order(:name)
			end
		end
		@psets = Pset.order(:order).all
		@groupless_count = User.active.no_group.not_admin.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count
		@title = 'List users'
		render 'grades', layout: 'full-width'
	end
	
	def grades_for_inactive
		@users = User.inactive.not_admin.order(:name)
		@psets = Pset.order(:order)
		@groupless_count = User.active.no_group.not_admin.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count
		@title = 'List users'
		render 'grades', layout: 'full-width'
	end
	
	def grades_for_other
		@users = User.active.no_group.not_admin.includes(:logins, :submits => [:pset, :grade]).order(:name)
		@psets = Pset.order(:order)
		@groupless_count = User.active.no_group.not_admin.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count
		@title = 'List users'
		render 'grades', layout: 'full-width'
	end
	
	def grades_for_admins
		@users = User.admin.order(:name)
		@psets = Pset.order(:order)
		@groupless_count = User.active.no_group.not_admin.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count
		@title = 'List users'
		render 'grades', layout: 'full-width'
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
