class HomeController < ApplicationController

    include NavigationHelper

    before_action :authorize,     except: [ :index, :manifest ]
    before_action :require_staff, except: [ :index, :manifest ]

    layout 'blank'

    def index
        if logged_in?
            if !current_user.valid_profile?
                # require profile completion
                redirect_to profile_path
            elsif !current_user.valid_schedule? && Schedule.many_registerable?
                redirect_to profile_path
            elsif current_user.admin? && !Settings.git_version.key?('.')
                # allow connecting course materials git
                redirect_to home_clone_path
            elsif Settings.hands_only && !current_user.staff?
                # if website is only used to manage assistance queue, student:
                redirect_to assistance_index_path
            elsif Settings.hands_only && current_user.assistant?
                # if website is only used to manage assistance queue, staff:
                redirect_to hands_path
            elsif alerts_for_current_schedule.any?
                # current user's schedule's announcements
                redirect_to announcements_path
            else
                current_user.set_current_schedule! if !current_user.valid_schedule?
                # current user's schedule's syllabus
                redirect_to syllabus_path
            end
        else
            logger.info "NOT logged in"
            if Page.find_by_slug('')
                # public syllabus as welcome page
                redirect_to syllabus_path
            else
                # basic course info + login buttons
                @page_name = t('account.login_or_register')
                @course_name = "Course Website"
            end
        end
    end

    def clone
        if Settings.git_repo.present?
            Course::Loader.new.run
            User.first.update(schedule: Schedule.first)
            return redirect_to :root
        end
        @page_name = "Set git repo"
        @course_name = "Course Website"
    end

end
