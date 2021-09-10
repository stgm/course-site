class Schedules::GenerateGroupsController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_admin

	layout 'modal'

	def new
		load_schedule
	end

	# Generate some number of groups and randomly assign students.
	def create
		load_schedule
		@schedule.generate_groups(params[:number].to_i)
		redirect_to schedule_path(@schedule), notice: 'Groups have been randomly assigned.'
	end

end
