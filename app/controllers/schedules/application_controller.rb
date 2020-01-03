class Schedules::ApplicationController < ApplicationController
	
	before_action :load_navigation

	private
	
	def load_schedule
		@schedule = Schedule.friendly.find(params[:schedule_slug])
	end
	
	def verify_access
		head :forbidden unless current_user.admin? || current_user.schedules.include?(@schedule)
	end
	
end
