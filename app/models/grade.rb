class Grade < ActiveRecord::Base

	belongs_to :submit
	has_one :user, through: :submit
	has_one :pset, through: :submit

	attr_accessible :comments, :correctness, :design, :grade, :grader, :scope, :style
	
	def grader_name
		if g = User.where(uvanetid: self.grader).first
			return g.name
		else
			return ""
		end
	end

end
