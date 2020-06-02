module Grading
	
	def self.final_grade_names
		Settings.grading['calculation'].keys
	end
	
end
