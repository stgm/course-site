class GradesController < ApplicationController

	before_action :authorize
	before_action :require_staff

	before_action :set_grade, except: :create

	layout false

	def create
		@grade = Grade.new(grade_params)
		@grade.grader = current_user
		@grade.save!

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
		# grades can only be edited if "open" or if user is admin
		if current_user.senior? || @grade.unfinished?
			@grade.update!(grade_params)
		end

		respond_to do |format|
			format.js do
				logger.info params[:commit]
				if params[:commit] == 'autosave'
					head :ok
				else
					@submit = @grade.submit
					redirect_js location: submit_path(@submit)
				end
			end
			format.html { redirect_back fallback_location:@grade }
		end
	end
	
	def reopen
		raise if @grade.unfinished?
		@grade.unfinished!
		@submit = @grade.submit
		redirect_js location: submit_path(@submit)
	end
	
	def reject
		@grade.update(grade:0)
		@grade.published!
		@submit = @grade.submit
		redirect_js location: submit_path(@submit)
	end

	def destroy
		@submit = @grade.submit
		@grade.destroy

		respond_to do |format|
			format.js do
				redirect_js location: submit_path(@submit)
			end
			format.html do
				redirect_back fallback_location: @submit
			end
		end
	end

	private
	
	def set_grade
		@grade = Grade.find(params[:id])
	end

	def grade_params
		params.require(:grade).permit!
	end

end
