# TODO factor out search
class UsersController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_admin, except: [ :show, :search ]
    before_action :require_staff, only: [ :show, :search ]
    before_action :set_user_scope

    layout "modal"

    def search
        if params[:text].present?
            if params[:text] == '---'
                @results = @user_scope.where(name: nil)
            else
                query = I18n.transliterate(params[:text].downcase)
                @results = @user_scope.where.not(name: nil).order(:name).select { |u| I18n.transliterate(u.name&.downcase)&.include?(query) || u.student_number&.include?(query) }.first(10)
            end
        else
            @results = []
        end
        respond_to do |format|
            format.html { render partial: 'search' }
        end
    end

    # Note: we use methods like `group_by_day` from the GroupDate gem. It
    # did not work with timezones + sqlite before, though now it should.
    # If any problems arise: previously timezones were disabled in dev
    # config by:
    #
    # # Remove time zone for Groupdate because it does not support SQLite
    # Groupdate.time_zone = false
    def show
        @student = @user_scope.includes(:notes).find(params[:id])
        @note = Note.new(student_id: @student.id)

        if current_user.senior?
            @schedules = Schedule.all
            @groups = @student.schedule && @student.schedule.groups.order(:name) || []
            @attend = @student.attendance_records.group_by_day(:cutoff).count
            @attend_confirmed = @student.attendance_records.where(confirmed: true).group_by_day(:cutoff).count
            @attend_raw = @student.attendance_records
                .where("cutoff > ?", Date.today.beginning_of_day).order(:cutoff)
            @items = @student.notes.includes(:author).order(created_at: :desc)

            @subs = @student.submits.includes(:grade).index_by { |i| [ i.pset_id, i.user_id ] }

            @overview = @student.grading_config.overview
        else
            @items = @student.notes.includes(:author).order(created_at: :desc)
            render "notes"
        end
    end

    def edit
        @student = @user_scope.find(params[:id])
    end

    def update
        @user = @user_scope.find(params[:id])
        @user.update!(params.require(:user).permit(
            :name,
            :pronouns,
            :status,
            :alarm,
            :status_description,
            :mail,
            :avatar,
            :notes,
            :schedule_id,
            :group_id,
            :student_number,
            :pin,
            :last_known_ip))
        respond_to do |format|
            format.js { head :ok }
            format.html { redirect_to @user }
        end
    end

    def calculate_final_grade
        # feature has to be enabled by supplying a grading.yml
        @user = @user_scope.find(params[:id])
        raise ActionController::RoutingError.new("Not Found") if not @user.can_assign_final_grade?
        result = @user.assign_final_grade(current_user, only: params[:grades])
        redirect_to @user
    end

    private

    # limits user operations to the scope allowed for the current user
    def set_user_scope
        @user_scope = current_user.accessible_students
    end

end
