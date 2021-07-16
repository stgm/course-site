# Manages submits in admin interfaces like /students and the student search
# -only course heads need access.
class SubmitsController < ApplicationController

	before_action :authorize
	before_action :require_senior, except: [:show, :update]
	before_action :require_staff, only: [:show, :update]

	layout 'modal'

	# Submit and grade editor.
	def show
		load_submit(params[:id])
	end

	# Create a completely new submit (without student interaction).
	def create
		submit = Submit.where(params[:submit].permit([:pset_id, :user_id])).first_or_create
		redirect_to submit
	end

	def update
		@submit = Submit.includes(:grade).find(params[:id])

		if current_user.senior? || @submit.grade.blank? || @submit.grade.unfinished?
			# update submit but also the linked grade
			@submit.update! params.require(:submit).permit!
		end

		if params[:commit] == 'autosave'
			head :ok
		else
			redirect_to @submit
		end
	end

	# Deletes submit and redirects to the previously associated student.
	def destroy
		@submit = Submit.find(params[:id])
		@user = @submit.user
		@submit.destroy
		redirect_to @user
	end

	# Sends files to check server and redirects to the previously associated student.
	def recheck
		@submit = Submit.find(params[:id])
		@submit.recheck(request.host)
		redirect_to user_path(@submit.user)
	end

	private

	def load_submit(id)
		@submit = Submit.includes(:grade, :user, :pset).find(id)
		@grade = @submit.grade || @submit.build_grade({ grader: current_user })
		@files = @submit.all_files
	end

end
