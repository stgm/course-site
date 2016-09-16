class StudentsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	before_action :load_attendance, only: [:list, :list_inactive, :list_other, :list_admins]
	before_action :load_stats

	layout 'full-width'

	def index
		@users = User.active.not_admin.includes({ :submits => :grade }, :hands, :logins, :group).order(:name)
	end

	def list_inactive
		@users = User.inactive.not_admin.order(:name)
		render 'grades'
	end
	
	def list_admins
		@users = User.admin.order(:name)
		render 'grades'
	end
	
	def show
		@student = User.includes(:hands).find(params[:id])
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @student.id).order('grades.created_at desc')
		render layout: 'application'
	end

	private
	
	def load_stats
		@active_count = User.active.not_admin.count
		@inactive_count = User.inactive.not_admin.count
		@admin_count = User.admin.count

		@psets = Pset.order(:order)
		@title = 'List users'
	end

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
				# user_attendance.append u.attendance_records.count
				u.update_attribute(:attendance, user_attendance.join(","))
			end
		end
	end

end
