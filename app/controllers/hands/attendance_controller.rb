class Hands::AttendanceController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_admin

    layout "navbar"

    before_action do
        @group_name = params["group"] ||  current_user.groups.first&.name || current_user.full_designation.gsub("\n", " &ndash; ")
        @course_name = Schedule.count > 1 && current_schedule.name || Course.long_name
        @reload_path = hands_path

        I18n.locale = "en"
    end

    def index
        @title = "Hands"
        @grouped_users = User.student
            .active
            .where(schedule: current_schedule)
            .order(:last_known_location, :name)
            .group_by(&:last_known_location)

        if Settings.hands_groups && params[:group]!="all"
            selected_group = Group.find_by_name(params["group"])
            @group = current_user.groups.first
            @hands = @hands.includes(:user).where(users: { group: selected_group || @group })
            @long_time_users = @long_time_users.where(users: { group: selected_group || @group })
        end
    end

end
