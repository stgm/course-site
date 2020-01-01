class Admin::UpdatesController < ModalController

	before_action :authorize
	before_action :require_admin
	
	#
	# update the courseware from the linked git repository
	#
	def create
		errors = CourseLoader.new.run
		logger.debug errors.join('<br>').inspect
		if errors.size > 0
			redirect_back fallback_location: '/', alert: errors.join('<br>')
		else
			redirect_back fallback_location: '/', notice: 'The course content was successfully updated.'
		end
	end

end
