class GradesController < ApplicationController

	before_action :authorize
	before_action :require_staff
	
	#todo check grading assignment for user
	
	layout false

	def show
		@grade = Grade.includes(submit: [ :user, :pset ]).find(params[:id])
	end
	
	def create
		@grade = Grade.create!(grade_params)

		respond_to do |format|
			format.js do
				@user = @grade.user
				@pset = @grade.pset
				@submit = @grade.submit
				render 'show'
			end
			format.html do
				redirect_to grading_path(submit_id:grade_params['submit_id'])
			end
		end
	end
	
	def update
		@grade = Grade.find(params[:id])
		if current_user.senior? || @grade.unfinished?
			# grades can only be edited if "open" or if user is admin
			@grade.update!(grade_params)
		# elsif current_user.assistant? && @submit.grade.published? && params["grade"]["status"] == "discussed"
		# 	@grade.update!(grade_params)
		end
		
		respond_to do |format|
			format.js do
				logger.info params[:commit]
				if params[:commit] == 'autosave'
					head :ok
				else
					@user = @grade.user
					@pset = @grade.pset
					@submit = @grade.submit
					render 'show'
				end
			end
			format.html { redirect_back fallback_location:@grade }
		end
	end
	
	# DELETE /grades/:id
	def destroy
		@grade = Grade.find(params[:id])
		@submit = @grade.submit

		@grade.destroy
		@grade = @submit.build_grade({ grader: current_user })

		respond_to do |format|
			format.js { render 'show' }
			format.html { redirect_back fallback_location:@submit }
		end
	end

	def templatize
		auto_feedback = Settings["course"]["feedback_templates"][params[:type]]
		submit = Submit.find(params[:id])
		@grade = submit.grade || submit.build_grade(grader: current_user)
		@grade.comments = auto_feedback["feedback"]
		@grade.grade = auto_feedback["grade"]
		@grade.status = Grade.statuses[:finished]
		@grade.save
		redirect_back fallback_location: '/'
	end
	
	private
	
	def grade_params
		params.require(:grade).permit!
	end
	
end
