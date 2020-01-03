class Schedules::OverviewsController < ApplicationController

	before_action :authorize
	before_action :require_staff

	def show
		
		if current_user.assistant?
			redirect_back(fallback_location: '/', alert: "You haven't been assigned a group yet!") and return if current_user.groups.empty?
			slug = current_user.groups.first
		elsif current_user.head?
			redirect_back(fallback_location: '/', alert: "You haven't been assigned a schedule yet!") and return if current_user.schedules.empty?
			slug = current_user.schedules.first
		elsif current_user.admin?
			slug = current_user.schedule
		end
		redirect_to(schedule_path(schedule_slug: slug)) and return

	end
	
end
