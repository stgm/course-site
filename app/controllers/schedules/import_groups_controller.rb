# Import group assignments from a CSV paste.
class Schedules::ImportGroupsController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_admin

	layout 'modal'

	def new
		load_schedule
		@paste = Settings.cached_user_paste
	end

	def propose
		load_schedule
		if @paste = params[:paste]
			Settings.cached_user_paste = @paste
			@result = @schedule.propose_groups(@paste)
		end
	end

	def create
		load_schedule
		if source = params[:paste]
			@schedule.import_groups(source)
		end
		redirect_to schedule_overview_path(@schedule), notice: 'Student groups were successfully imported.'
	end

end
