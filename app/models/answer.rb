class Answer < ActiveRecord::Base
	belongs_to :user
	belongs_to :pset
	attr_accessible :answer_data
end
