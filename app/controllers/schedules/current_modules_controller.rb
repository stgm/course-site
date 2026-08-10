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

    private

    def load_schedule
        # allow overriding schedule in params, else use user's own schedule
        @schedule = params[:schedule_id] &&
                    Schedule.find(params[:schedule_id]) ||
                    current_user.schedule
    end

end
