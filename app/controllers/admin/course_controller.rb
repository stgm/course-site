class Admin::CourseController < ApplicationController

	include NavigationHelper

	before_action :authorize
	before_action :require_admin

	layout 'modal'

	def index
		@schedule_spans = current_schedule && current_schedule.schedule_spans.order(:rank) || []

		@geregistreerd = User.student.count
		@gestart = User.student.joins(:submits).uniq.count
		@gestopt = User.student.status_inactive.joins(:submits).uniq.count
		@bezig = @gestart - @gestopt
		final = Pset.find_by_name('final')
		@gehaald = User.student.joins(:grades => :submit).where('submits.pset_id = ?', final).uniq.count
	end

	#
	# update the courseware from the linked git repository
	#
	def import
		errors = Course::Loader.new.run
		if errors.size > 0
			redirect_back fallback_location: '/', alert: errors.join('<br>')
		else
			redirect_back fallback_location: '/', notice: 'The course content was successfully updated.'
		end
	end

	#
	# export all course grades in XLSX or HTML format (archiving)
	#
	def export_grades
		@users = User.student.joins(:submits).uniq
		@psets = Pset.joins(:submits).distinct.order(:order)
		@title = "Export grades"

		# all users who ever submitted something
		@students = User.joins(:submits).distinct.order(:name)

		respond_to do |format|
			format.xlsx
			format.html { render layout: false }
		end
	end

	#
	# make schedule parts public or not
	#
	def update_schedule_span
		p = ScheduleSpan.find(params[:id])
		p.update!(params.require(:schedule_span).permit(:public))
		head :ok
	end

	#
	# allow user registration for some schedule
	#
	def schedule_registration
		p = Schedule.find(params[:id])
		p.update!(params.require(:schedule).permit(:self_register))
		head :ok
	end

	#
	# allow users of some schedule to browse the full schedule
	# otherwise the course manager needs to set the "current" schedule
	#
	def schedule_self_service
		p = Schedule.find(params[:id])
		p.update!(params.require(:schedule).permit(:self_service))
		head :ok
	end

end
