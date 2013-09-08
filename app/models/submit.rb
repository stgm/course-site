class Submit < ActiveRecord::Base
	belongs_to :user
	belongs_to :pset
	has_one :grade
	attr_accessible :submitted_at
end
