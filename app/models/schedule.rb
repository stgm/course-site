class Schedule < ActiveRecord::Base
	has_many :schedule_spans
	attr_accessible :description, :name
end
