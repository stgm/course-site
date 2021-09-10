class Schedules::AddGroupsController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_admin

	layout 'modal'

	def new
		load_schedule
	end

	# Generate some number of groups and randomly assign students.
	def create
		load_schedule
		@schedule.add_group(params[:name])
		redirect_to overview_path(@schedule), notice: "Group <b>#{params[:name]}</b> has been added."
	end

end
