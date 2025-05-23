class PageController < ApplicationController

    include NavigationHelper
    include AttendanceRecorder

    before_action :authorize, only: [ :index ], if: :request_from_local_network?
    before_action :authorize, only: [ :submit, :questions, :announcements ]

    before_action :load_page_components, only: [ :index, :submit, :questions ]

    def index
        redirect_to page_submit_path(slug: params[:slug]) and return if @only_submit
        @subpages = @page.subpages.select { |x| x.title.downcase != "submit" }
        @title = @page.title
    end

    def submit
        @subpages = @page.subpages.select { |x| x.title.downcase == "submit" }
        if @page.pset
            @submit = Submit.find_or_initialize_by(user: current_user, pset: @page.pset)
            @allow_submit = @submit.allow_new_submit?
            @deadline = @submit.deadline
        end
        @title = @page.title
    end

    def questions
        redirect_to({ action: :index }) if !@may_show_questions
        @title = @page.title
        @questions = @page.questions.includes(:user, :rich_text_text, answers: [ :user, :rich_text_text ]).order(updated_at: :desc).all
    end

    def announcements
        @title = t(:announcements)
    end

    private

    def load_page_components
        if params[:slug] == "syllabus"
            @page = Page.syllabus
        else
            @page = Page.where(slug: params[:slug]).includes(:subpages).first
        end

        raise ActionController::RoutingError.new("Not Found") and return if !@page

        @only_submit = @page.subpages.any? && @page.subpages.select { |x| x.title.downcase != "submit" }.none?

        @may_show_content = !@only_submit
        @may_show_questions = logged_in? && !@only_submit && Settings.qa_allow
        @may_show_submit = @page.pset && @page.pset.exam.blank?
        true
    end

end
