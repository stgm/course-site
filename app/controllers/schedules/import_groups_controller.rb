#
# import group assignments from a CSV paste
#
class Schedules::ImportGroupsController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_admin
	
	layout 'wide'

	def new
		load_schedule
		@paste = Settings.cached_user_paste
	end
	
	def create
		load_schedule
		# this is very dependent on datanose export format: ids in col 0 and 1, group name in 7
		if source = params[:paste]
			Settings.cached_user_paste = source
			@schedule.import_groups(source)
		end
		redirect_to @schedule, notice: 'Student groups were successfully imported.'
	end

end
