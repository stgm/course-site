class CourseController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	#
	# update the courseware from the linked git repository
	#
	def import
		errors = CourseLoader.new.run
		logger.debug errors.join('<br>').inspect
		if errors.size > 0
			logger.debug "yes error"
			redirect_to :back, alert: errors.join('<br>')
		else
			redirect_to :back, notice: 'The course content was successfully updated.'
		end
	end
	
end
