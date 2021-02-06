# TODO factor out search
class UsersController < ApplicationController

	before_action :authorize
	before_action :require_senior
	
	layout 'modal'

	def search
		if params[:text] != ""
			@results = User.includes(:logins).where("users.name like ? or logins.login like ?", "%#{params[:text]}%", "%#{params[:text]}%").references(:logins).limit(10).order(:name)
		else
			@results = []
		end
		respond_to do |format|
			format.js
		end
	end

	def show
		@student = User.includes(:hands, :notes).find(params[:id])
		@schedules = Schedule.all
		@groups = @student.schedule && @student.schedule.groups.order(:name) || []
		@note = Note.new(student_id: @student.id)
		@items = @student.items(true)
		@psets = Pset.ordered_by_grading
		
		@attend = @student.attendance_records.group_by_day(:cutoff, format: "%a %d-%m").count
	end

	def edit
		@student = User.find(params[:id])
		
	end

	def update
		@user = User.find(params[:id])
		@user.update!(params.require(:user).permit(:name, :active, :done, :status, :mail, :avatar, :notes, :schedule_id, :group_id, :alarm))
		redirect_to @user
	end

	def calculate_final_grade
		# feature has to be enabled by supplying a grading.yml
		raise ActionController::RoutingError.new('Not Found') if not Grading::FinalGradeAssigner.available?
		@user = User.find(params[:id])
		result = Grading::FinalGradeAssigner.assign_final_grade(@user, current_user, only: params[:grades])
		redirect_to @user
	end

end
