class Answer < ActiveRecord::Base
	belongs_to :user
	belongs_to :page
	attr_accessible :answer_data
end
