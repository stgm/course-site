class Admin::UsersController < ApplicationController
	
	include ApplicationHelper
	
	before_action :authorize
	before_action :require_admin

	#
	# permissions modal
	#
	def index
		@users = User.staff.order(:role, :name)
		@schedules = Schedule.order(:name)
		@groups = Group.includes(:schedule).order('schedules.name').order('groups.name')

		render_to_modal header: 'User permissions', in_place_editing: true
	end
	
	def new
		@user = User.new
		render_to_modal header: 'Add user'
	end
	
	def create
		@u = User.new(params.require(:user).permit(:name, :mail, :schedule_id))
		@u.student!
		@u.generate_token!
		@url = root_url(token: @u.token)
		render_to_modal header: "User #{@u.name} added"
	end
	
	# PUT /user/:user_id/admin
	def set_role
		p = User.find(params[:user_id])
		p.update!(params.require(:user).permit(:role))

		respond_to do |format|
			format.json { p }
			format.html { redirect_back fallback_location: '/' }
			format.js { redirect_js location: user_path(p) }
		end
	end
	
	def add_group_permission
		load_user
		load_group
		@user.groups << @group unless @user.groups.include?(@group)
		respond_js 'set_group_permissions'
	end
	
	def remove_group_permission
		load_user
		load_group
		@user.groups.delete(@group)
		respond_js 'set_group_permissions'
	end
	
	def add_schedule_permission
		load_user
		load_schedule
		@user.schedules << @schedule unless @user.schedules.include?(@schedule)
		respond_js 'set_schedule_permissions'
	end
	
	def remove_schedule_permission
		load_user
		load_schedule
		@user.schedules.delete(@schedule)
		respond_js 'set_schedule_permissions'
	end

	private
	
	def load_user
		@user = User.find(params[:user_id])
	end
	
	def load_group
		@group = Group.friendly.find(params[:group_id])
	end
	
	def load_schedule
		@schedule = Schedule.friendly.find(params[:schedule_id])
	end
	
	def respond_js(partial_name)
		respond_to do |format|
			format.html { redirect_back fallback_location: '/' }
			format.js { render partial: partial_name }
		end
	end
	
end
