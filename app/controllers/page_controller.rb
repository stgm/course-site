class PageController < ApplicationController

    include NavigationHelper
    include AttendanceRecorder

    before_action :authorize, if: :request_from_local_network?
    before_action :validate_profile

    def index
        # find page by url and bail out if not found
        @page = Page.where(slug: params[:slug]).first
        raise ActionController::RoutingError.new('Not Found') if !@page

        @subpages = @page.subpages

        if @page.pset && current_user.can_submit?
            @has_form = @page.pset.form
            @submit = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).first
            @allow_submit = @submit.blank? || @submit.may_be_resubmitted?
        end

        @title = @page.title

        if not logged_in?
            render layout: 'navbar' and return
        end
    end

    def syllabus
        @page = current_schedule && current_schedule.page || Page.find_by_slug('')
        raise ActionController::RoutingError.new('Not Found') if !@page
        @subpages = @page.subpages
        @title = t(:syllabus)

        if not logged_in?
            render 'index', layout: 'navbar' and return
        end
        render 'index'
    end

end
