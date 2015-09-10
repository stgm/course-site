class Grade < ActiveRecord::Base

	belongs_to :submit
	has_one :user, through: :submit
	has_one :pset, through: :submit

	attr_accessible :comments, :correctness, :design, :grade, :grader, :scope, :style, :done
	
	def grade
		g = read_attribute(:grade)
		return nil if !g
		g = (g/10.0).round(1)
		return g
	end
	
	def grade=(new_grade)
		if new_grade.blank? # erases the grade
			return super(nil)
		elsif new_grade.class == String
			new_grade.sub!(/,/,'.')
			case self.pset.grade_type
			when 'float'
				super(10.0 * new_grade.to_f)
			else # integer, pass
				super(10.0 * new_grade.to_i)
			end
		end
	end
	
	def grader_name
		Rails.logger.info self.grader.inspect
		if g = User.find_by_login(self.grader)
			return g.name
		else
			return ""
		end
	end

end
