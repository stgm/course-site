class GradingController < ApplicationController

    #
    # Manages the list of submits to be graded by assistants
    # -all staff needs access, but the grading list is filled according to assigned groups
    #

    before_action :authorize
    before_action :require_staff

    before_action :load_grading_list, only: [ :index, :show ]

    # GET /grading
    def index
        # immediately redirect to first thing that might be graded
        if g = @to_grade&.first
            redirect_to grading_path(g, params.permit(:pset, :group, :status))
        end
    end

    # GET /grading/:submit_id
    def show
        # extract all psets that are to be graded by user (before filtering)
        @psets_to_grade = Pset.find(@to_grade.pluck(:pset_id))

        # apply filters to selection
        filter_grading_list

        # reload without filters if nothing to grade with filters
        redirect_to({ action: :index }) and return if @to_grade.first.blank?

        # load the selected submit and any grade that might be attached
        @submit = Submit.includes(:grade, :user, :pset).find(params[:submit_id])

        # load a different submit if the current submit does not belong to the current selection
        redirect_to grading_path(@to_grade.first, params.permit(:pset, :group, :status)) if not @to_grade.include?(@submit)

        # load the associated grade and files
        @grade = @submit.grade || @submit.build_grade({ grader: current_user })
        @files = @submit.all_files_and_form

        # load other grades for summarizing
        @grades = Grade.joins(:submit).includes(:submit).where("submits.user_id = ?", @submit.user.id).order("submits.created_at desc")

        @title = "Grading"
    end

    # GET /grading/:submit_id/download
    def download
        @submit = Submit.find(params[:grading_submit_id])
        @file = @submit.file_contents[params[:filename]]
        send_data @file, type: "text/plain", filename: params[:filename]
    end

    # GET /grading/finish
    def finish
        # allow grader to mark as finished so the grades may be published later
        # TODO some of the constraints can be moved to model
        @grades = Grade.where("grade is not null or calculated_grade is not null").joins(:user).unfinished.where(users: { status: "active" }).where(grader: current_user)
        @grades.update(status: Grade.statuses[:finished])# , updated_at: DateTime.now)
        redirect_back fallback_location: "/", alert: "Thank you for grading with us today!"
    end

    private

    def load_grading_list
        if !Schedule.exists? # current_user.admin? || !Schedule.exists?
            # admins get everything to be graded (in all schedules and groups)
            @to_grade = Submit.to_grade
        elsif current_user.admin?
            # admins get everything from their current schedule (they can switch schedules)
            @to_grade = Submit.admin_to_grade.where("users.schedule_id" => current_user.schedule)
        elsif current_user.head? && current_user.schedules.any?
            # heads get stuff from the current schedule, only from assigned groups (to save clutter)
            @to_grade = Submit.to_grade.where("users.schedule_id" => current_user.schedule).
            where("users.group_id in (?)", current_user.groups.pluck(:id))
        elsif current_user.assistant? && (Group.any? || Schedule.any?) && (current_user.groups.any? || current_user.schedules.any?)
            # other assistants get stuff only from their assigned group
            @to_grade = Submit.to_grade.where(
                [ "users.group_id in (?) or users.schedule_id in (?)", current_user.groups.pluck(:id), current_user.schedules.pluck(:id) ])
        elsif current_user.assistant? && !(Group.any? || Schedule.any?)
            # assistants get everything if there are no groups or schedules
            # but nothing if there are groups and they haven't been assigned one yet
            @to_grade = Submit.to_grade
        end

        if @to_grade.blank?
            redirect_out("You haven't been assigned grading groups yet!")
        end
    end

    def filter_grading_list
        if params[:group]
            @to_grade = @to_grade.where(users: { group_id: params[:group] })
        end
        if params[:status]
            @to_grade = @to_grade.where(grades: { status: params[:status] })
        end
        if params[:pset]
            @to_grade = @to_grade.where(psets: { name: params[:pset] })
        end
    end

    def redirect_out(message = nil)
        message ||= "There's nothing to grade from your grading groups!"
        if not request.referer&.match?(/grading/)
            redirect_back(fallback_location: "/", alert: message) and return
        else
            redirect_to :root
        end
    end

end
