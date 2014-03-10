class Schedule < ActiveRecord::Base
	belongs_to :track
	has_many :schedule_spans
	attr_accessible :description, :name
end
