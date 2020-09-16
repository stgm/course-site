class Schedules::SchedulesController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_senior
	before_action :load_schedule # needed to verify access
	before_action :verify_access

	#
	# set "current" schedule that is displayed to users
	#
	def set_current_module
		if params[:item] == "0"
			@schedule.update_attribute(:current, nil)
		else
			@schedule.update_attribute(:current, ScheduleSpan.find(params[:item]))
		end
		render json: nil
	end

end
