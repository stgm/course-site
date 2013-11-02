class Grade < ActiveRecord::Base

	belongs_to :submit

	attr_accessible :comments, :correctness, :design, :grade, :grader, :scope, :style
	
	def grader_name
		if g = User.where(uvanetid: self.grader).first
			return g.name
		else
			return ""
		end
	end

end
