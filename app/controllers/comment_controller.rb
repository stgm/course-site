class CommentController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter

	def post_question
		content = params[:comment]
		if content.strip.length > 0
			# first, create a new thread
			page = params[:page_id]
			thread = CommentThread.create(:page_id => page)
	
			# then post the comment
			user = current_user.id
			comment = Comment.create(user_id: user, content: content, comment_thread_id:thread.id)
		end

		redirect_to :back
	end
	
	def post_answer
		content = params[:comment]
		if content.strip.length > 0
			user = current_user.id
			thread_id = params[:thread_id]
			comment = Comment.create(user_id: user, content: content, comment_thread_id:thread_id)
		end

		redirect_to :back
	end
	
	def delete_question
		t = CommentThread.find(params[:thread_id])
		t.comments.delete_all
		t.delete
		redirect_to :back
	end
	
	def delete_answer
		Comment.find(params[:comment_id]).delete
		redirect_to :back
	end

end
