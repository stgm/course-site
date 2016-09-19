class StudentsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin

	before_action :load_stats
	layout 'full-width'

	def index
		@users = User.active.not_admin_or_assistant.includes(:group).order("groups.name").order(:name).group_by(&:group)
		@submits = Submit.includes(:grade).group_by(&:user_id)
	end

	def list_inactive
		@users = User.inactive.not_admin_or_assistant.order(:name).group_by(&:group)
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	def list_admins
		@users = User.admin_or_assistant.order(:name).group_by(&:group)
		@submits = Submit.includes(:grade).group_by(&:user_id)
		render "index"
	end
	
	def show
		@student = User.includes(:hands).find(params[:id])
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @student.id).order('grades.created_at desc')
		@groups = Group.order(:name)
		render layout: 'application'
	end

	private
	
	def load_stats
		@active_count = User.active.not_admin_or_assistant.count
		@inactive_count = User.inactive.not_admin_or_assistant.count
		@admin_count = User.admin_or_assistant.count
		@psets = Pset.order(:order)
		@title = 'List users'
	end

end
