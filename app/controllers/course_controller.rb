require 'course_loader'

class CourseController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	before_action :load_attendance, only: [:grades_for_group, :grades_for_inactive, :grades_for_other, :grades_for_admins]


	def load_attendance
		if !Settings['attendance_last_calced'] || Settings['attendance_last_calced'] < 3.hours.ago
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
		errors = CourseLoader.new.run
		logger.info errors.join('<br>').inspect
		if errors.size > 0
			logger.info "yes error"
			redirect_to :back, alert: errors.join('<br>')
		else
			redirect_to :back, notice: 'The course content was successfully updated.'
		end
	end
	
	def assign_final_grade
		User.find(params[:id]).assign_final_grade(@current_user.login_id)
		render nothing:true
	end
	
	def change_user_name
		User.find(params[:id]).update!(params.require(:user).permit(:name))
		render json:true
	end

	#
	# list all submits
	#
	def grades_for_group
		if params[:group].present?
			@users = Group.find_by_name(params[:group]).users.active.includes(:logins, :submits => [:pset, :grade]).order(:name)
		else
			if Group.count > 0
				@users = Group.order(:name).first.users.active.includes(:logins, :submits => [:pset, :grade]).order(:name)
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
	
	#
	# update submit date for single submit, in order to get it into the queue again
	#
	def touch_submit
		s = Submit.find(params[:submit_id])
		s.update!(submitted_at: Time.now)
		g = s.grade.update!(done: false)
		redirect_to :back
	end
	
end
