class Submit < ActiveRecord::Base

	belongs_to :user
	belongs_to :pset

	has_one :grade

	attr_accessible :submitted_at, :url, :used_login

	def graded?
		return (self.grade && !self.grade.grade.blank?)
	end

end
