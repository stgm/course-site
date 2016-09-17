class StudentsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	before_action :load_stats

	layout 'full-width'

	def index
		@users = User.active.not_admin.includes({ :submits => :grade }, :group).order(:name)
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
		@groups = Group.order(:name)

		@active_count = User.active.not_admin.count
		@inactive_count = User.inactive.not_admin.count
		@admin_count = User.admin.count

		@psets = Pset.order(:order)
		@title = 'List users'
	end

end
