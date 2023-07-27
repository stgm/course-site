class QuestionsController < ApplicationController

    before_action :authorize

    def index
        @page = Page.where(slug: params[:slug]).first
        @questions = @page.questions.order(updated_at: :desc).all
        render 'page/questions'
    end

    def show
        @question = Question.find(params[:id])
    end

    def new
        @page = Page.where(slug: params[:slug]).first
    end

    def create
        @question = Question.create!(question_params.merge({ user_id: current_user.id }))
        redirect_to questions_path(slug: @question.page.slug)
    end

    private

    def question_params
        params.require(:question).permit(:text, :page_id)
    end

end
