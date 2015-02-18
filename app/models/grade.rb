class Grade < ActiveRecord::Base

	belongs_to :submit
	has_one :user, through: :submit
	has_one :pset, through: :submit

	attr_accessible :comments, :correctness, :design, :grade, :grader, :scope, :style
	
	def grade
		g = (read_attribute(:grade)/10.0).round(1)

		case pset.grade_type
		when 'float'
			return g
		else # integer, pass
			return g.to_i
		end
	end
	
	def grade=(new_grade)
		new_grade.sub!(/,/,'.') if new_grade.class == String
		case pset.grade_type
		when 'float'
			super(10.0 * new_grade.to_f)
		else # integer, pass
			super(10.0 * new_grade.to_i)
		end

	end
	
	def grader_name
		if g = User.where(uvanetid: self.grader).first
			return g.name
		else
			return ""
		end
	end

end
