class AdminController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	def export_grades
		@users = User.not_admin_or_assistant.joins(:submits).uniq.order('name')
		@psets = Pset.order(:id)
		@title = "Export grades"
		respond_to do |format|
		    response.headers['Content-Disposition'] = 'attachment; filename="Grades ' + Settings.short_course_name + '.xls"'
			format.xls
		end
	end
	
	def dump_grades
		@students = User.order(:name)
		render layout: false
	end
	
	def pages
		@all_sections = Section.includes(pages: :pset)
		@schedules = ScheduleSpan.all
		@schedule_position = Settings.schedule_position && ScheduleSpan.find_by_id(Settings.schedule_position) || ScheduleSpan.new
	end
	
	def page_update
		p = Page.find(params[:id])
		p.update!(params.require(:page).permit(:public))
		render json: p
	end
	
	def set_schedule
		Settings.schedule_position = params[:id]
		render json: nil
	end
	
	def stats
		@geregistreerd = User.not_admin_or_assistant.count
		@gestart = User.not_admin_or_assistant.joins(:submits).uniq.count
		@gestopt = User.not_admin_or_assistant.inactive.joins(:submits).uniq.count
		@bezig = @gestart - @gestopt
		final = Pset.find_by_name('final')
		@gehaald = User.not_admin_or_assistant.joins(:grades => :submit).where('submits.pset_id = ?', final).uniq.count
	end

	#
	# divide users into groups from a csv
	#
	def import
		@paste = Settings.cached_user_paste
	end
	
	def import_groups
		# this is very dependent on datanose export format: ids in col 0 and 1, group name in 7
		if source = params[:paste]
			Settings.cached_user_paste = source
			Group.import(source)
		end
		redirect_to students_path, notice: 'Student groups were successfully imported.'
	end

end
