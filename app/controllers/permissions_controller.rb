class PermissionsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	def index
		@users = User.staff.order(:name)
		@schedules = Schedule.all
		@groups = Group.all
	end
	
end
