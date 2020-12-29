class Admin::UsersController < ApplicationController

	include ApplicationHelper

	before_action :authorize
	before_action :require_admin

	layout 'modal'

	# Show user permissions modal.
	def index
		@users = User.staff.order(:role, :name)
		@schedules = Schedule.order(:name)
		@groups = Group.includes(:schedule).order('schedules.name').order('groups.name')
	end

	def new
		@user = User.new
	end

	def create
		@u = User.new(params.require(:user).permit(:name, :mail, :schedule_id))
		@u.student!
		@u.generate_token!
		@url = root_url(token: @u.token)
	end

	# Unused at this point, because we haven't implemented a dropdown role choice.
	def set_role
		p = User.find(params[:user_id])
		p.update!(params.require(:user).permit(:role))

		respond_to do |format|
			format.json { p }
			format.html { redirect_to p }
		end
	end

	def add_group_permission
		load_user
		load_group
		@user.groups << @group unless @user.groups.include?(@group)
		redirect_to admin_users_path
	end

	def remove_group_permission
		load_user
		load_group
		@user.groups.delete(@group)
		redirect_to admin_users_path
	end

	def add_schedule_permission
		load_user
		load_schedule
		@user.schedules << @schedule unless @user.schedules.include?(@schedule)
		redirect_to admin_users_path
	end

	def remove_schedule_permission
		load_user
		load_schedule
		@user.schedules.delete(@schedule)
		redirect_to admin_users_path
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

end
