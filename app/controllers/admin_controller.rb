class AdminController < ApplicationController

	before_action :authorize
	before_action :require_senior
	
	def export_grades
		@users = User.student.joins(:submits).uniq
		@psets = Pset.order(:order)
		@title = "Export grades"
		respond_to do |format|
			format.xlsx
		end
	end
	
	def to_export
		final_grade_names = Settings.grading['calculation'].keys
		@psets = Pset.where(name: final_grade_names)
		@grades = Grade.joins([submit: :pset]).includes(user: [:schedule, :group]).where(submits: { pset_id: @psets }).published.order('schedules.name', 'psets.name', 'groups.name')

		respond_to do |format|
			format.html
			format.xlsx
		end
	end
	
	def to_export_do
		final_grade_names = Settings.grading['calculation'].keys
		@psets = Pset.where(name: final_grade_names)
		@grades = Grade.joins([submit: :pset]).includes(user: [:schedule, :group]).where(submits: { pset_id: @psets }).published
		@grades.update_all(status: Grade.statuses['exported'])
		redirect_back fallback_location: '/'
	end

	def dump_grades
		@students = User.order(:name)
		render layout: false
	end
	
	def set_schedule
		if params[:item] == "0"
			Schedule.find(params[:schedule]).update_attribute(:current, nil)
		else
			Schedule.find(params[:schedule]).update_attribute(:current, ScheduleSpan.find(params[:item]))
		end
		render json: nil
	end
	
	def stats
		@geregistreerd = User.student.count
		@gestart = User.student.joins(:submits).uniq.count
		@gestopt = User.student.inactive.joins(:submits).uniq.count
		@bezig = @gestart - @gestopt
		final = Pset.find_by_name('final')
		@gehaald = User.student.joins(:grades => :submit).where('submits.pset_id = ?', final).uniq.count
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
			@schedule = Schedule.find(params[:schedule_id])
			@schedule.import_groups(source)
		end
		redirect_to students_in_group_path(group: @schedule.name), notice: 'Student groups were successfully imported.'
	end
	
	def generate_groups
		@schedule_param = Schedule.find(params[:schedule_id])
	end
	
	def generate_groups_do
		# the schedule that is currently the selected tab
		schedule = Schedule.find(params[:schedule_id])
		schedule.generate_groups(params[:number].to_i)
				
		redirect_to students_in_group_path(group: Schedule.find(params[:schedule_id]).name), notice: 'Groups have been randomly assigned.'
	end

end
