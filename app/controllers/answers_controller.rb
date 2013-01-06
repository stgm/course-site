class AnswersController < ApplicationController

	# POST /answers
	# POST /answers.json
	def create

		if logged_in?

			pset = Page.find(params[:page_id]).pset
			
			@answer = Answer.where(:user_id => current_user.id, :pset_id => pset.id).first_or_initialize
			@answer.answer_data = params[:a].to_json

			respond_to do |format|
				if @answer.save
					format.html { redirect_to @answer, :notice => 'Answer was successfully created.' }
					format.json { render :json => @answer, :status => :created, :location => @answer }
				else
					format.html { render :action => "new" }
					format.json { render :json => @answer.errors, :status => :unprocessable_entity }
				end
			end

		end

	end

end
