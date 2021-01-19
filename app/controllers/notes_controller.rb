class NotesController < ApplicationController

	before_action :authorize
	before_action :require_senior

	def show
		set_note
		# render 'items/note'
	end

	def create
		@note = Note.create(note_params.merge({ author_id: current_user.id }))
		redirect_to user_path(@note.student)
	end

	def edit
		set_note
	end

	def update
		set_note
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

	def note_params
		params.require(:note).permit(:text, :author_id, :student_id, :done, :assignee_id)
	end

end
