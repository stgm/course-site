class Submit < ActiveRecord::Base

	belongs_to :user
	belongs_to :pset

	has_one :grade, dependent: :destroy

	def graded?
		return (self.grade && (!self.grade.grade.blank? || !self.grade.calculated_grade.blank?))
	end

end
