class AttendanceController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_admin

    layout "navbar"

    # Staff take attendance by hand: the site can see that a student loaded a
    # page, but only a person can confirm they are actually in the room.
    def index
        @title = "Attendance"
        @course_name = Schedule.count > 1 && current_schedule.name || Course.long_name
        @students = User.student
            .status_active_or_registered
            .where(schedule: current_schedule)
            .order(:name)
    end

    def confirm
        user = User.find(params[:user_id])
        user.confirm_attendance!(params[:attendance][:confirmed])
        redirect_back fallback_location: attendance_path
    end

    def clear_all
        User.where(schedule: current_schedule).update_all(attendance_confirmed: false)
        redirect_back fallback_location: attendance_path
    end

end
