class UsersController < ApplicationController
	
	# include ApplicationHelper
	
	before_action :authorize
	before_action :require_senior

	# GET /manage/users/:id.js
	def show
		@student = User.includes(:hands, :notes).find(params[:id])
		@schedules = Schedule.all
		@groups = @student.schedule && @student.schedule.groups.order(:name) || []
		@note = Note.new(student_id: @student.id)
		@items = @student.items(true)
		@psets = Pset.order(Arel.sql("'order' IS NULL"), :order)
	end
	
	# PATCH /manage/users/:id
	def update
		@user = User.find(params[:id])
		@user.log_changes_for(current_user)
		@user.update_attributes!(params.require(:user).permit(:name, :active, :done, :status, :mail, :avatar, :notes, :schedule_id, :group_id, :alarm))

		respond_to do |format|
			format.json { respond_with_bip(p) }
			format.html { redirect_back fallback_location: '/' }
			format.js { redirect_js location: user_path(@user) }
		end
	end
	
	# PATCH /manage/users/:id/calculate_final_grade
	def calculate_final_grade
		# feature has to be enabled by supplying a grading.yml
		raise ActionController::RoutingError.new('Not Found') if not Grading::FinalGradeAssigner.available?
		@user = User.find(params[:id])
		result = Grading::FinalGradeAssigner.assign_final_grade(@user, current_user, only: params[:grades])

		respond_to do |format|
			format.html { redirect_back fallback_location: '/' }
			format.js { redirect_js location: user_path(@user) }
		end
	end
	
end
