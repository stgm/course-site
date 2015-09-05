class Schedule < ActiveRecord::Base
	has_many :schedule_spans, dependent: :destroy
	attr_accessible :description, :name
end
