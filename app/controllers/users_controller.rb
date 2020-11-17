class UsersController < ApplicationController

	# include ApplicationHelper

	before_action :authorize
	before_action :require_senior

	# GET /manage/users/search/users?text=.. for admins + heads
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

	# GET /manage/users/:id.js
	def show
		@student = User.includes(:hands, :notes).find(params[:id])
		@schedules = Schedule.all
		@groups = @student.schedule && @student.schedule.groups.order(:name) || []
		@note = Note.new(student_id: @student.id)
		@items = @student.items(true)
		@psets = Pset.ordered_by_grading

		render_to_modal header_partial: 'title', action: 'show', in_place_editing: true
	end

	# PATCH /manage/users/:id
	def update
		@user = User.find(params[:id])
		@user.update!(params.require(:user).permit(:name, :active, :done, :status, :mail, :avatar, :notes, :schedule_id, :group_id, :alarm))

		respond_to do |format|
			format.json { @user }
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
