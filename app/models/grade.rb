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
		
	def set_calculated_grade
		if calculated_grade = calculate_grade(self)
			self.update_attribute(:calculated_grade, calculated_grade*10)
		else
			self.update_attribute(:calculated_grade, nil)
		end
	end

	private
	
	def calculate_grade(grade)
		f = Settings['grading']['formulas']
		return nil if f.nil?
		pset_name = grade.pset.name
		return nil if f[pset_name].nil?
		begin
			cg = grade.instance_eval(f[pset_name])
		rescue
			cg = nil
		end
		return cg
	end

end
