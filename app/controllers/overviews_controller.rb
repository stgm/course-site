class OverviewsController < ApplicationController

    before_action :authorize
    before_action :require_staff

    def index
        if current_user.assistant?
            redirect_back(fallback_location: '/', alert: "You haven't been assigned a group yet!") and return if current_user.groups.empty?
            slug = current_user.schedule
            redirect_to(overview_path(slug)) and return if slug.present?
        elsif current_user.head?
            redirect_back(fallback_location: '/', alert: "You haven't been assigned a schedule yet!") and return if current_user.schedules.empty?
            slug = current_user.schedules.first
            redirect_to(overview_path(slug)) and return if slug.present?
        elsif current_user.admin?
            # default to currently selected schedule
            slug = current_user.schedule
            redirect_to(overview_path(slug)) and return if slug.present?
        end

        redirect_back(fallback_location: '/', alert: 'No schedules') and return if slug.blank?
    end

    def show
        # check which schedules this user is allowed to view
        @accessible_schedules = current_user.accessible_schedules
        @selected_schedule = Schedule.friendly.find(params[:id])
        @groups = current_user.groups.where(schedule: @selected_schedule) if !current_user.admin?
        load_data
        render 'overview'
    end

    private

    def load_data
        @name = @selected_schedule.name
        @status = params[:status]
        @psets = Pset.ordered_by_grading
        @grouped_psets = @psets.index_by &:name

        @users = @selected_schedule.users.not_staff
        @users = @users.where(group: @groups) if !current_user.admin? && @groups.any?
        @title = 'List users'

        @active_count = @users.status_active.count
        @registered_count = @users.status_registered.count
        @inactive_count = @users.status_inactive.count
        @done_count = @users.status_done.count

        @users = @users.
            includes(:group, { submits: [:pset, :grade] }).
            order("groups.name").
            order(:name)

        case params[:status]
        when 'active'
            @users = @users.status_active
        when 'registered'
            @users = @users.status_registered
        when 'inactive'
            @users = @users.status_inactive
        when 'done'
            @users = @users.status_done
        end

        @subs = Submit.where(user: @users).
            includes(grade: :pset).
            index_by{|i| [i.pset_id, i.user_id]}

        @users = @users.group_by(&:group)

        @overview = GradingConfig.overview
    end

end
