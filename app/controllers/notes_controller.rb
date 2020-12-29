class NotesController < ApplicationController

	before_action :authorize
	before_action :require_senior

	def create
		@note = Note.create(note_params.merge({ author_id: current_user.id }))
		redirect_to user_path(@note.student)
	end

	private

	def note_params
		params.require(:note).permit(:text, :author_id, :student_id)
	end

end
