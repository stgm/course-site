class OverviewsController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_staff
    # before_action :require_senior, only: [ :show ]
    before_action :check_permissions

    layout "navbar"

    def index
        if Settings.grading_single_overview_page && current_user.admin?
            show_all_schedules
        else
            redirect_to_default_schedule
        end
    end

    def show
        load_accessible_schedules
        load_accessible_groups if @accessible_schedules.none?

        if @accessible_schedules.blank? && @accessible_groups.blank?
            redirect_back fallback_location: "/",
                alert: "You haven't been assigned groups or a schedule yet!"
            return
        end

        load_selected_schedule_or_default
        load_data

        if @users.blank?
            redirect_back fallback_location: "/",
                alert: "You have no students yet!"
            return
        end

        begin
            render "overview"
        # rescue
        #     redirect_to :root, alert: "Overview CRASHED, please reload courseware to check config files if needed."
        end
    end

    private

    def check_permissions
        if current_user.assistant? &&
           !Settings.grading_overview_for_tas
            render plain: "404 Not Found", status: 404
        elsif current_user.head? &&
              current_user.accessible_schedules.empty? &&
              current_user.accessible_groups.empty?
            redirect_to root_url, alert: "You haven't been assigned a schedule yet!"
        end
    end

    def show_all_schedules
        load_accessible_schedules
        load_data
        @schedules = @accessible_schedules
        @title = "List users"
        render "overview"
    end

    def redirect_to_default_schedule
        if current_user.schedule.present?
            redirect_to overview_path(current_user.schedule)
        else
            redirect_back fallback_location: "/", alert: "You do not have a schedule yourself."
        end
    end

    def load_accessible_schedules
        @accessible_schedules = current_user.accessible_schedules
    end

    def load_accessible_groups
        @accessible_groups = current_user.accessible_groups
    end

    def load_selected_schedule_or_default
        @selected_schedule = if @accessible_schedules.any?
            @accessible_schedules.friendly.find(params[:id])
        else
            current_user.schedule
        end
    end

    def load_data
        @name = @selected_schedule&.name
        @status = params[:status]
        @title = "List users"

        load_relevant_users
        load_status_counts

        # load relevant submits
        @subs = Submit.indexed_by_pset_and_user_for @users
    end

    def load_relevant_users
        if @accessible_schedules&.any? && Settings.grading_single_overview_page
            # all schedules on single page
            @users = User.not_staff.where(schedule: @accessible_schedules)
        elsif @accessible_groups&.any?
            # for staff who only have access to a few groups
            @users = User.not_staff.where(group: @accessible_groups)
        elsif @selected_schedule.present?
            # single schedule selected
            @users = @selected_schedule.users.not_staff
        end
    end

    def load_status_counts
        @active_count = @users.status_active.count
        @registered_count = @users.status_registered.count
        @inactive_count = @users.status_inactive.count
        @done_count = @users.status_done.count
    end

end
