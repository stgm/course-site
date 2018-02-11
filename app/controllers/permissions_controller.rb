class PermissionsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_senior
	
	def index
		@users = User.staff.order(:role, :name)
		@schedules = Schedule.all
		@groups = Group.all

		if current_user.admin?
			render :edit
		elsif current_user.head?
			render :show
		end
	end
	
end
