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
	
	def assign_final_grade
		User.all.each do |u|
			u.assign_final_grade(@current_user.login_id)
		end
		redirect_to :back
	end
	
	#
	# update submit date for single submit, in order to get it into the queue again
	#
	def touch_submit
		s = Submit.find(params[:submit_id])
		s.update!(submitted_at: Time.now)
		g = s.grade.update!(done: false)
		redirect_to :back
	end
	
	def mark_all_public
		@grades = Grade.finished
		@grades.update_all(status: Grade.statuses[:published])
		redirect_to :back
	end

end
