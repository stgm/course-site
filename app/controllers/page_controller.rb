class PageController < ApplicationController

    include NavigationHelper
    include AttendanceRecorder

    before_action :authorize, only: [ :index ], if: :request_from_local_network?
    before_action :authorize, only: [ :announcements ]

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
        @questions = @page.questions.order updated_at: :desc
    end

    def submit
        # find page by url and bail out if not found
        @page = Page.where(slug: params[:slug]).first
        raise ActionController::RoutingError.new('Not Found') if !@page
        
        if @page.pset && current_user.can_submit?
            @has_form = @page.pset.form
            @submit = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).first
            @allow_submit = @submit.blank? || @submit.may_be_resubmitted?
        end
        
        @title = @page.title
        
    end

    def questions
        # find page by url and bail out if not found
        @page = Page.where(slug: params[:slug]).first
        raise ActionController::RoutingError.new('Not Found') if !@page
        
        if @page.pset && current_user.can_submit?
            @submit = Submit.where(:user_id => current_user.id, :pset_id => @page.pset.id).first
        end
        
        @title = @page.title
        @questions = @page.questions.order updated_at: :desc
        
    end

    def announcements
        @title = t(:announcements)
    end

    def syllabus
        if @page = current_schedule && current_schedule.page || Page.find_by_slug('')
        else
            @page = Page.new
        end
        @subpages = @page.subpages
        @title = t(:syllabus)
        render 'index'
    end

end
