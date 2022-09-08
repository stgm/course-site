class HomeController < ApplicationController

    include NavigationHelper

    before_action :authorize,     except: [ :index ]
    before_action :require_staff, except: [ :index ]

    layout 'welcome'

    def index
        if logged_in?
            if !current_user.valid_profile?
                # require profile completion
                redirect_to profile_path
            elsif !current_user.valid_schedule? && Schedule.many_registerable?
                redirect_to profile_path
            elsif !current_user.valid_schedule?
                current_user.set_current_schedule!
                redirect_to syllabus_path
            elsif current_user.admin? && !Settings.git_version.key?('.')
                # allow connecting course materials git
                redirect_to home_clone_path
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
            end
        end
    end

    def clone
        if Settings.git_repo.present?
            Course::Loader.new.run
            User.first.update(schedule: Schedule.first)
            return redirect_to :root
        end
    end

end
