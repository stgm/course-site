module GradingHelper
	
	def grade_color(grade)
		return '' if grade.nil?
		return 'success' if grade.done
		return 'info'
	end
	
end
