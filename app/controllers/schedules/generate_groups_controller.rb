class Schedules::GenerateGroupsController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_admin
	
	def new
		load_schedule
		render_to_modal header: 'Generate groups'
	end
	
	# generate a number of groups and randomly assign students
	# the schedule that is currently the selected tab
	def create
		load_schedule
		@schedule.generate_groups(params[:number].to_i)
		redirect_to schedule_overview_path(@schedule), notice: 'Groups have been randomly assigned.'
	end
	
end
