class GradeTools
	
	@log = ""

	def self.available?
		!!Settings['grading'] && !!Settings['grading']['calculation']
	end

	def initialize
		@grading = Settings['grading']
	end
	
	def log(something)
		@log ||= ""
		@log << something + "\n"
	end
	
	def get_log
		@log
	end
	
	def calc_final_grade_formula(subs, formula)
		total        = 0
		total_weight = 0
		insufficient = false
		missing_data = false
		exam_done    = false
		
		formula.each do |subtype, weight|
			log("    - #{subtype}")
			grade = calc_final_grade_subtype(subs, subtype)
			
			missing_data = true if grade == nil  # missing grades, so we might return nil
			insufficient = true if grade == 0    # grade came back 0, so we'll return insuff later
			exam_done    = true if grade && @grading[subtype]['exam'].present? && @grading[subtype]['exam']
			
			log("      exam = #{exam_done}, missing = #{missing_data}, insuff = #{insufficient}")
			
			# we can immediately assign insuff if a grade that requires a minimum (exam) is insuff
			if grade == 0 && (@grading[subtype]['minimum'].present? ||
				              @grading[subtype]['required'].present?)
				return 0
			end

			if grade != nil
				total += grade * weight
				total_weight += weight
			end
		end
		
		if exam_done && missing_data
			# exam done but still missing data to pass
			return 0
		elsif missing_data
			# if we have grades missing (except if exam was failed, see above)
			return nil
		elsif insufficient
			# if any part is insufficient (e.g., below minimum)
			# this won't do much, no difference with the exam thing above
			return 0
		else
			# otherwise we can actually calculate
			return uva_round(total.to_f / total_weight.to_f)
		end
	end
	
	private
	
	def uva_round(grade)
		return 5 if grade >= 4.75 && grade < 5.5
		return 6 if grade >= 5.5 && grade < 6.25
		return 10 if grade > 10
		return (2.0 * grade).round(0) / 2.0
	end
	
	def calc_final_grade_subtype(subs, subtype)
		return 0 if !@grading[subtype]['submits']

		total = 0
		total_weight = 0
		
		grades = []
		
		grades << calc_subtype_with_potential_drop(subs, subtype, @grading[subtype]['minimum'], nil)
		
		log("        - final result: #{grades.max}")
		return grades.max
	end
	
	def calc_subtype_with_potential_drop(subs, subtype, needs_minimum, droppable_grade)
		log("        - subtype: #{subtype} trying to drop #{droppable_grade.pset.name if droppable_grade}")
		total = 0
		total_weight = 0
		@grading[subtype]['submits'].each do |grade, weight|
			log("            - #{grade}")
			
			# the maximum of multiple grades may be used, when specified as an array
			#   e.g. mario: [12, mario, mario-more]
			if weight.is_a?(Array)
				real_weight = weight.first # first element is weight
				log("              choosing from multiple: #{weight}")
				# get all grades for those assignments and take maximum, ignoring non-grades
				grade = weight.drop(1).map { |grade_name| 
					if subs[grade_name]
						subs[grade_name].any_final_grade || 0
					else
						0
					end
				}.max
				log("                                    : #{grade}")

				# can't find grade so return nil
				log("max is 0") and return nil if grade == 0
				total += grade * real_weight
				total_weight += real_weight
			elsif weight == "bonus"
				total += subs[grade].any_final_grade if subs[grade].present?
			else
				# can't find grade so return nil
				log("this grade is nil") and return nil if subs[grade].nil? or subs[grade].any_final_grade.nil? #or subs[grade].any_final_grade == 0
			
				if subs[grade] != droppable_grade
					total += subs[grade].any_final_grade * weight
					total_weight += weight
				end
			end
		end
		log("            - total #{total} / weight #{total_weight}")
		final = (1.0 * total.round(2) / total_weight)
		log("            - result: #{final}")
		if !needs_minimum.present? && !@grading[subtype]['required'].present?
			return final
		elsif needs_minimum.present? && final >= needs_minimum
			return final
		elsif @grading[subtype]['required'].present? && final.abs == 1
			return final
		else
			return 0
		end
	end
	
end
