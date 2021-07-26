# TODO factor out search
class UsersController < ApplicationController

    before_action :authorize
    before_action :require_senior, except: :show
    before_action :require_staff, only: :show
    before_action :set_user_scope

    layout 'modal'

    def search
        if params[:text] != ""
            @results = @user_scope.
                includes(:logins).
                where("users.name like ? or logins.login like ?", "%#{params[:text]}%", "%#{params[:text]}%").
                references(:logins).
                limit(10).
                order(:name)
        else
            @results = []
        end
        respond_to do |format|
            format.js
        end
    end

    def show
        @student = @user_scope.includes(:hands, :notes).find(params[:id])
        @note = Note.new(student_id: @student.id)

        if current_user.senior?
            @schedules = Schedule.all
            @groups = @student.schedule && @student.schedule.groups.order(:name) || []
            @psets = Pset.ordered_by_grading
            @attend = @student.attendance_records.group_by_day(:cutoff, format: "%a %d-%m").count
            @items = @student.notes.includes(:author).order(created_at: :desc)

            @subs = @student.submits.includes(:grade).index_by{|i| [i.pset_id, i.user_id]}
            @indexed_psets = @psets.index_by(&:name)

            @overview = GradingConfig.overview
        else
            @items = @student.notes.includes(:author).order(created_at: :desc)
            render 'notes'
        end
    end

    def edit
        @student = @user_scope.find(params[:id])
    end

    def update
        @user = @user_scope.find(params[:id])
        @user.update!(params.require(:user).permit(
            :name,
            :status,
            :alarm,
            :status_description,
            :mail,
            :avatar,
            :notes,
            :schedule_id,
            :group_id))
        respond_to do |format|
            format.js { head :ok }
            format.html { redirect_to @user }
        end
    end

    def calculate_final_grade
        # feature has to be enabled by supplying a grading.yml
        raise ActionController::RoutingError.new('Not Found') if not Grading::FinalGradeAssigner.available?
        @user = @user_scope.find(params[:id])
        result = Grading::FinalGradeAssigner.assign_final_grade(@user, current_user, only: params[:grades])
        redirect_to @user
    end

    private

    # limits user operations to the scope allowed for the current user
    def set_user_scope
        @user_scope = case current_user.role
        when 'assistant'
            current_user.students
        when 'head'
            User.where(schedule: current_user.accessible_schedules)
        when 'admin'
            User
        end
    end

end
