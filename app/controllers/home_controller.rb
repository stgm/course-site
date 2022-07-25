class HomeController < ApplicationController

    include NavigationHelper
    include AttendanceRecorder

    def index
        if logged_in?
            if alerts_for_current_schedule.any?
                # current user's schedule's announcements
                redirect_to announcements_path
            else
                # current user's schedule's syllabus
                redirect_to syllabus_path
            end
        else
            if Page.find_by_slug('')
                # public syllabus as welcome page
                redirect_to syllabus_path
            else
                # basic course info + login buttons
                render layout: 'welcome'
            end
        end
    end

end
