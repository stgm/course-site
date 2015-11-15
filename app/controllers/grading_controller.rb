class GradingController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin_or_assistant

	#
	# List of problems to be graded by assistants
	#
	def index
		if current_user.is_admin?
			@submits = Submit.includes(:user, :pset, :grade)
		else
			@submits = Submit.includes(:user, :pset, :grade).where("submits.submitted_at > grades.updated_at or grades.updated_at is null or grades.public = ?", false)
		end
		@submits = @submits.where(pset_id:params[:pset]) if not params[:pset].blank?
		@submits = @submits.where("users.group_id" => params[:group]) if not params[:group].blank?
		@submits = @submits.order('psets.name')
		@groups = Group.all
		@psets = Pset.all
	end
	
	#
	# List of checkables for assistants
	#
	def checklist
		if params[:group].present?
			@users = Group.find_by_name(params[:group]).users.includes(:logins, :submits => [:pset, :grade]).order(:name)
		else
			if Group.count > 0
				@users = Group.order(:name).first.users.includes(:logins, :submits => [:pset, :grade]).order(:name)
			else
				@users = User.active.no_group.not_admin.includes(:logins, :submits => [:pset, :grade]).order(:name)
			end
		end
		@psets = Pset.where(grade_type: Pset.grade_types[:pass]).order(:order)
		@title = 'List users'
		render 'checklist', layout: 'full-width'
	end
	
	private
	
end
