class Admin::CourseController < ApplicationController

	before_action :authorize
	before_action :require_admin
	
	def index
		# TODO
		@all_sections = [] #Section.includes(pages: :pset)
		
		@geregistreerd = User.student.count
		@gestart = User.student.joins(:submits).uniq.count
		@gestopt = User.student.inactive.joins(:submits).uniq.count
		@bezig = @gestart - @gestopt
		final = Pset.find_by_name('final')
		@gehaald = User.student.joins(:grades => :submit).where('submits.pset_id = ?', final).uniq.count
		
		render_to_modal header: 'Course administration'
	end

	#
	# update the courseware from the linked git repository
	#
	def import
		errors = Course::Loader.new.run
		logger.debug errors.join('<br>').inspect
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
		@psets = Pset.order(:order)
		@title = "Export grades"
		@students = User.order(:name)
		respond_to do |format|
			format.xlsx
			format.html { render layout: false }
		end
	end

	#
	# show/hide pages
	#
	def page_update
		p = Page.find(params[:id])
		p.update!(params.require(:page).permit(:public))
		render json: p
	end

	#
	# allow user registration for some schedule
	#
	def schedule_registration
		p = Schedule.find(params[:id])
		p.update!(params.require(:schedule).permit(:self_register))
		render json: p
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
