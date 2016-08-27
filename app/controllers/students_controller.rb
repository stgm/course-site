class StudentsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	before_action :load_attendance, only: [:list, :list_inactive, :list_other, :list_admins]
	before_action :load_stats

	layout 'full-width'

	def list
		if params[:group].present?
			@users = Group.friendly.find(params[:group]).users.active.includes(:logins, :submits => [:pset, :grade]).order(:name)
			render 'grades'
		elsif Group.count > 0
			redirect_to({ action: 'list', group:Group.order(:name).first.slug })
		else
			redirect_to({ action: 'list_other' })
		end
	end

	def list_inactive
		@users = User.inactive.not_admin.order(:name)
		render 'grades'
	end
	
	def list_other
		@users = User.active.no_group.not_admin.includes(:logins, :submits => [:pset, :grade]).order(:name)
		render 'grades'
	end
	
	def list_admins
		@users = User.admin.order(:name)
		render 'grades'
	end

	private
	
	def load_stats
		if Group.count > 0
			@groups = Group.order(:name)
			@group_counts = User.where(active: true).group(:group_id).count
		end

		@groupless_count = User.active.no_group.not_admin.active.count
		@admin_count = User.admin.order(:name).count
		@inactive_count = User.inactive.not_admin.count

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
