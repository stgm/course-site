class Admin::UsersController < ApplicationController
	
	include ApplicationHelper
	
	before_action :authorize
	before_action :require_admin

	#
	# permissions modal
	#
	def index
		@users = User.staff.order(:role, :name)
		@schedules = Schedule.all
		@groups = Group.all

		render_to_modal header: 'User permissions'
	end
	
	# PUT /user/:user_id/admin
	def set_role
		p = User.find(params[:user_id])
		p.update!(params.require(:user).permit(:role))

		respond_to do |format|
			format.json { respond_with_bip(p) }
			format.html { redirect_back fallback_location: '/' }
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
