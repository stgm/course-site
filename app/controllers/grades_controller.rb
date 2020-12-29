class GradesController < ApplicationController

	before_action :authorize
	before_action :require_staff

	before_action :set_grade, except: :create

	layout false

	# def create
	# 	@grade = Grade.new(grade_params)
	# 	@grade.grader = current_user
	# 	@grade.save!
	#
	# 	respond_to do |format|
	# 		format.js do
	# 			@user = @grade.user
	# 			@pset = @grade.pset
	# 			@submit = @grade.submit
	# 			render 'show'
	# 		end
	# 		format.html do
	# 			redirect_to grading_path(submit_id:grade_params['submit_id'])
	# 		end
	# 	end
	# end

	# def update
	# 	# grades can only be edited if "open" or if user is admin
	# 	if current_user.senior? || @grade.unfinished?
	# 		@grade.update!(grade_params)
	# 	end
	# 	redirect_to @grade.submit
	# end

	def reopen
		raise if @grade.unfinished?
		@grade.unfinished!
		@submit = @grade.submit
		redirect_to @submit
	end

	def reject
		@grade.update(grade:0)
		@grade.published!
		@submit = @grade.submit
		redirect_to @submit
	end

	def destroy
		@submit = @grade.submit
		@grade.destroy
		redirect_to submit_path(@submit)
	end

	private

	def set_grade
		@grade = Grade.find(params[:id])
	end

	def grade_params
		params.require(:grade).permit!
	end

end
