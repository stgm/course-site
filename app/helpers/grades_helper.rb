module GradesHelper
	
	def translate_grade(grade)
		return "error" if grade.nil? or grade < -1
		return "pass" if grade == -1
		return "fail" if grade == 0
		return grade/10.0 if grade > 10
		return grade.to_s
	end
	
end
