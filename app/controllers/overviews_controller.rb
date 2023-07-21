class OverviewsController < ApplicationController

    before_action :authorize
    before_action :require_staff
    before_action :require_senior, only: [ :show ]

    layout 'navbar'
    before_action :check_inactives, only: [ :index ]

    def index
        if current_user.assistant?
            @accessible_schedules = Schedule.none
            @groups = current_user.groups
            @users = User.where(group: @groups).not_staff.status_active
            @users = @users.
                includes(:group, { submits: [:pset, :grade] }).
                order("groups.name").
                order(:name)
            @subs = Submit.indexed_by_pset_and_user_for @users

            @grouped_users = @users.group_by(&:group)
            logger.info @grouped_users.keys
            @overview = GradingConfig.overview
            render 'overview' and return
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
        @selected_schedule = @accessible_schedules.friendly.find(params[:id])
        @groups = current_user.groups.where(schedule: @selected_schedule) if !current_user.senior?
        load_data
        render 'overview'
    end

    private

    def load_data
        @name = @selected_schedule.name
        @status = params[:status]

        @users = @selected_schedule.users.not_staff
        @users = @users.where(group: @groups) if !current_user.senior? && @groups.any?
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

        @subs = Submit.indexed_by_pset_and_user_for @users

        @grouped_users = @users.group_by(&:group)

        @overview = GradingConfig.overview
    end

    def check_inactives
        User.set_inactives_to_inactive!
    end

end
