class Comment < ActiveRecord::Base
  attr_accessible :comment_thread, :content, :orig_content, :user
end
