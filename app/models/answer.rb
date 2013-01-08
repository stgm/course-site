class Answer < ActiveRecord::Base
	belongs_to :user
	belongs_to :pset
	attr_accessible :answer_data, :user_id, :pset_id
end
