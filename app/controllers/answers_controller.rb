class AnswersController < ApplicationController
    
    def new
        @question = Question.find(params[:question_id])
    end

    def create
        @answer = Answer.create!(answer_params.merge({ user_id: current_user.id }))
        redirect_to question_path(@answer.question.id)
    end

    private
    
    def answer_params
        params.require(:answer).permit(:text, :question_id)
    end

end
