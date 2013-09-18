module GradesHelper
	
	def translate_grade(grade)
		return "unknown" if grade < -1 or grade > 10
		return "pass" if grade == -1
		return "fail" if grade == 0
		return grade.to_s
	end
	
end
