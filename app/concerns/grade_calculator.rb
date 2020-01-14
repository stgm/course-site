module GradeCalculator
	
	extend ActiveSupport::Concern

	included do
		before_save :set_calculated_grade
	end

	def set_calculated_grade
		if subgrades_changed?
			calculated_grade = calculate_grade(self)
			if calculated_grade.present?
				case self.pset.grade_type
				when 'float'
					# calculated_grade = calculated_grade
				else # integer, pass
					calculated_grade = calculated_grade.round
				end
				self.calculated_grade = calculated_grade * 10
			else
				self.calculated_grade = nil
			end
		end
	end
	
	def calculate_grade
		calculations = Settings['grading']['grades'] if Settings['grading']
		return nil if calculations.nil?
		
		pset_name = self.pset.name
		return nil if calculations[pset_name].nil? or calculations[pset_name]['calculation'].nil?
		
		begin
			cg = self.subgrades.instance_eval(calculations[pset_name]['calculation'])
		rescue
			cg = nil
		end
		
		return cg
	end
		
end
