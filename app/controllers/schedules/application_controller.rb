class Schedules::ApplicationController < ApplicationController

	private

	def load_schedule
		@schedule = Schedule.friendly.find(params[:schedule_slug])
		head :forbidden unless current_user.admin? || current_user.schedules.include?(@schedule)
	end

	def load_group
		@selected_schedule = Group.friendly.find(params[:schedule_slug])
		head :forbidden unless current_user.admin? || current_user.groups.include?(@selected_schedule)
	end

	def verify_access
		head :forbidden unless current_user.admin? || current_user.schedules.include?(@schedule)
	end

end
