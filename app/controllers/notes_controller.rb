class NotesController < ApplicationController

	before_action :authorize
	before_action :require_senior

	before_action :set_note, only: [:show, :edit, :update, :destroy]

	# GET /notes
	def index
		@notes = Note.all
	end

	# GET /notes/1
	def show
		if request.xhr?
			render :popup, layout: false
		end
	end
	
	# GET /notes/new
	def new
		@note = Note.new
	end

	# GET /notes/1/edit
	def edit
	end

	# POST /notes
	def create
		@note = Note.new(note_params.merge( {author_id: current_user.id}))
		
		if @note.save
			redirect_back fallback_location: '/', notice: 'Note was successfully created.'
		else
			render :new
		end
	end

	# PATCH/PUT /notes/1
	def update
		if @note.update(note_params)
			redirect_to @note, notice: 'Note was successfully updated.'
		else
			render :edit
		end
	end

	# DELETE /notes/1
	def destroy
		@note.destroy
		redirect_to notes_path, notice: 'Note was successfully destroyed.'
	end

	private
	# Use callbacks to share common setup or constraints between actions.
	def set_note
		@note = Note.find(params[:id])
	end

	# Only allow a trusted parameter "white list" through.
	def note_params
		params.require(:note).permit(:text, :author_id, :student_id)
	end

end
