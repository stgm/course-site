class CommentThread < ActiveRecord::Base
	has_many :comments
	attr_accessible :page_id, :title
end
