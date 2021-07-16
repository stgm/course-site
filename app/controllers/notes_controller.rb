class NotesController < ApplicationController
    before_action :authorize
    before_action :require_staff
    before_action :require_admin, only: :index

    before_action :set_note, only: [:show, :edit, :update]
    before_action :check_permission, only: [:show, :edit, :update]

    def index
        @notes = Note.includes(:student).where(log: false).order(created_at: :desc).limit(30)
        @max_submits = 30
        @students = User.student.not_status_inactive.
            includes(:group, { submits: [:pset, :grade] }).
            order("groups.name").
            order(:id).
            group_by(&:group)
        render layout: 'navbar'
    end

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
        params.require(:note).permit(:text, :author_id, :student_id, :done)
    end
end
