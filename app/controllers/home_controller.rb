class HomeController < ApplicationController

    include NavigationHelper

    def index
        if logged_in?
            if !current_user.valid_profile?
                # require profile completion
                redirect_to profile_path
            elsif current_user.admin? && Settings.git_repo.blank?
                # allow connecting course materials git
                redirect_to welcome_clone_path
            elsif alerts_for_current_schedule.any?
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
