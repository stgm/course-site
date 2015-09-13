module GradingHelper
	
	def grade_color(grade)
		return '' if grade.nil?
		return 'success' if grade['public']
		return 'info' if grade.done
		return 'warning'
	end
	
end
