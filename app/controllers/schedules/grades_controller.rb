class Schedules::GradesController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_senior
	before_action :load_schedule
	before_action :verify_access

	# reopen all "finished" grades for some group + pset combo
	def reopen
		@group = Group.find(params[:group_id])
		@group.grades.finished.where(submits: { pset_id: params[:pset_id] }).update_all(:status => Grade.statuses[:unfinished])
		redirect_back fallback_location: '/'
	end
	
	# publish grades for single pset (TODO embed in menu)
	def publish
		pset = Pset.find(params[:pset_id])
		@schedule.grades.joins(submit: :user).where(submits: { pset_id: pset.id }).find_each do |grade|
			grade.update(status: Grade.statuses[:published])
		end
		redirect_back fallback_location: '/'
	end
	
	# mark grades public that have been marked as "finished" by the grader
	def publish_finished
		@schedule.grades.finished.each &:published!
		redirect_back fallback_location: '/'
	end
	
	def form_for_publish_auto
		# render status: :forbidden and return if not verify_access?
		
		@psets = Pset.where(automatic: true).order(:order)
		# render layout: "application"
	end

	def publish_auto
		ids = []
		params[:psets].each do |name|
			pset = Pset.find_by_name(name)
			ids << pset.id
		end
		
		@schedule.submits.where(pset_id: ids).each do |s|
			if s.grade.nil?
				g = s.build_grade
				if g.subgrades.correctness == 5
					g.published!
				end
			end
		end
		
		redirect_to schedule_overview_path(@schedule)
	end
	
	# mark only my own grades public, and even when not marked as finished
	def publish_my
		@schedule.grades.where(grader: current_user).each &:published!
		redirect_back fallback_location: '/'
	end

	# try to make all grades public, but only valid grades
	def publish_all
		@schedule.grades.where.not(status: [Grade.statuses[:published], Grade.statuses[:exported]]).each &:published!
		redirect_back fallback_location: '/'
	end
	
	def assign_all_final
		# feature has to be enabled by supplying a grading.yml
		raise ActionController::RoutingError.new('Not Found') if not Grading::FinalGradeAssigner.available?
		
		@schedule.users.each do |student|
			Grading::FinalGradeAssigner.assign_final_grade(student, current_user, only: params[:grades])
		end
		redirect_back fallback_location: '/'
	end
	
	private
	
	def grade_params
		params.require(:grade).permit!
	end
	
end
