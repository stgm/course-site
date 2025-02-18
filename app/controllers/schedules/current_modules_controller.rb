class Schedules::CurrentModulesController < ApplicationController

    before_action :authorize
    before_action :require_admin
    before_action :load_schedule

    layout "modal"

    # Show all modules from the current schedule.
    def edit
        @schedule = current_user.schedule
    end

    # Set "current" schedule that is displayed to users.
    def update
        if params[:item] == "0"
            @schedule.update_attribute(:current, nil)
        else
            @schedule.update_attribute(:current, ScheduleSpan.find(params[:item]))
        end

        # immediately show change in actual sidebar
        render partial: "sidebar"
    end

    # Show final grades to be exported as official results.
    def to_export
        # TODO grade export currently just uses the base config
        @psets = Pset.where(name: GradingConfig.base.final_grade_names)

        @grades = Grade.
            joins([ submit: :pset ]).
            includes(user: [ :schedule, :group ]).
            where(submits: { pset_id: @psets }).
            published.
            order("schedules.name", "psets.name", "groups.name")

        respond_to do |format|
            format.html
            format.xlsx
        end
    end

    # Mark final grades as exported.
    def to_export_do
        # TODO grade export currently just uses the base config
        @psets = Pset.where(name: GradingConfig.base.final_grade_names)
        @grades = Grade.joins([ submit: :pset ]).includes(user: [ :schedule, :group ]).where(submits: { pset_id: @psets }).published
        @grades.update_all(status: Grade.statuses["exported"])
        redirect_back fallback_location: "/"
    end

    private

    def load_schedule
        # allow overriding schedule in params, else use user's own schedule
        @schedule = params[:schedule_id] &&
                    Schedule.find(params[:schedule_id]) ||
                    current_user.schedule
    end

end
