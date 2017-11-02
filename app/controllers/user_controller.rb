class UserController < ApplicationController
	
	include ApplicationHelper
	
	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_senior

	def show
		@schedules = Schedule.all
		@student = User.includes(:hands).find(params[:id])
		@grades = Grade.joins(:submit).includes(:submit).where('submits.user_id = ?', @student.id).order('grades.created_at desc')
		@groups = Group.order(:name)
		render layout: 'application'
	end
	
	def update
		p = User.find(params[:id])
		p.update_attributes!(params.require(:user).permit(:name, :active, :status, :mail, :avatar, :notes, :role, :schedule_id))

		respond_to do |format|
			format.json { respond_with_bip(p) }
			format.html { redirect_to :back }
		end
	end
	
	#
	# put submit into grading queue
	#
	def touch_submit
		s = Submit.find(params[:submit_id])
		s.grade.open! if s.grade
		redirect_to :back
	end

	
	def assign_group
		p = User.find(params[:user_id])
		g = Group.friendly.find(params[:group_id])
		
		p.group = g
		p.save
		
		redirect_to :back
	end
	
	def assign_schedule
		p = User.find(params[:user_id])
		g = Schedule.find(params[:schedule_id])
		
		p.schedule = g
		p.group = nil
		p.save
		
		redirect_to :back
	end
	
	def calculate_final_grade
		# feature has to be enabled in grading.yml - otherwise play stupid
		raise ActionController::RoutingError.new('Not Found') if not GradeTools.available?

		u = User.find(params[:user_id])
		result = u.assign_final_grade(current_user)
		Settings.debug_alert = simple_markdown("#{result}\n".html_safe)
		redirect_to :back
	end
	
end
