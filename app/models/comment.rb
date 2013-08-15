class Comment < ActiveRecord::Base
	belongs_to :user
	attr_accessible :comment_thread_id, :content, :orig_content, :user_id
end
