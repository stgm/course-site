class CourseController < ApplicationController

	before_action :authorize
	before_action :require_admin
	
	#
	# update the courseware from the linked git repository
	#
	def import
		errors = CourseLoader.new.run
		logger.debug errors.join('<br>').inspect
		if errors.size > 0
			logger.debug "yes error"
			redirect_back fallback_location: '/', alert: errors.join('<br>')
		else
			redirect_back fallback_location: '/', notice: 'The course content was successfully updated.'
		end
	end
	
end
