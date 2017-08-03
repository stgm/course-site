class AdminController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_senior
	
	def export_grades
		@users = User.student.joins(:submits).uniq.order('name')
		@psets = Pset.order(:id)
		@title = "Export grades"
		respond_to do |format|
		    response.headers['Content-Disposition'] = 'attachment; filename="Grades ' + Settings.short_course_name + '.xls"'
			format.xls
		end
	end

	def export_subgrades
		@users = User.student.joins(:submits).uniq.order('name')
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
		@schedules = Schedule.all.includes(:schedule_spans)
		# @schedules = ScheduleSpan.all
		# @schedule_position = Settings.schedule_position && ScheduleSpan.find_by_id(Settings.schedule_position) || ScheduleSpan.new
	end
	
	def page_update
		p = Page.find(params[:id])
		p.update!(params.require(:page).permit(:public))
		render json: p
	end
	
	def section_update
		p = Section.find(params[:id])
		p.update!(params.require(:page).permit(:display))
		render json: p
	end

	def set_schedule
		if params[:item] == "0"
			Schedule.find(params[:schedule]).update_attribute(:current, nil)
		else
			Schedule.find(params[:schedule]).update_attribute(:current, ScheduleSpan.find(params[:item]))
		end
		render json: nil
	end
	
	def schedule_set_self_register
		p = Schedule.find(params[:id])
		p.update!(params.require(:schedule).permit(:self_register))
		render json: p
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
			Group.import(source)
		end
		redirect_to students_path, notice: 'Student groups were successfully imported.'
	end
	
	def generate_groups
		@schedule_param = Schedule.find(params[:schedule_id])
	end
	
	def generate_groups_do
		# the schedule that is currently the selected tab
		schedule = Schedule.find(params[:schedule_id])
		
		# delete old groups for this schedule
		Group.where("name like ?", "#{schedule.name}%").delete_all
		
		# create the requested number of groups
		for n in 0..params[:number].to_i-1
			Group.create(name: "#{schedule.name} #{(n+65).chr}")
		end
		
		# randomize students
		students = User.student.where(schedule: params[:schedule_id]).shuffle
		
		# get the new groups
		groups = Group.where("name like ?", "#{schedule.name}%").to_a
		
		# divide students into groups and assign their group each
		students.in_groups(params[:number].to_i).each do |student_group|
			User.where("id in (?)", student_group).update_all(group_id: groups.pop.id)
		end
		
		redirect_to students_in_group_path(group: Schedule.find(params[:schedule_id]).name), notice: 'Groups have been randomly assigned.'
	end

end
