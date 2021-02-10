class NotesController < ApplicationController
	before_action :authorize
	before_action :require_staff

	before_action :set_note, only: [:show, :edit, :update]
	before_action :check_permission, only: [:show, :edit, :update]

	def show
	end

	def create
		@note = Note.create(note_params.merge({ author_id: current_user.id }))
		redirect_to user_path(@note.student)
	end

	def edit
	end

	def update
		if @note.update(note_params)
			redirect_to @note
		else
			render :edit
		end
	end

	private

	def set_note
		@note = Note.find(params[:id])
	end

	def check_permission
		current_user.admin? ||
			@note.author == current_user ||
			current_user.students.find(@note.student)
	end

	def note_params
		params.require(:note).permit(:text, :author_id, :student_id, :done, :assignee_id)
	end
end
