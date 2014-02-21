class Registration < ActiveRecord::Base

	belongs_to :user
	belongs_to :track

	attr_accessible :term, :status, :user, :track

end
