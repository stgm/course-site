class GradeTools
	
	@@log = ""

	def self.available?
		!!Settings['grading'] && !!Settings['grading']['calculation']
	end

	def initialize
		@grading = Settings['grading']
	end
	
	def log(something)
		@@log << something + "\n"
	end
	
	def get_log
		@@log
	end
	
	# def calc_final_grade(subs)
	# 	logger.info "Trying to calculate final grade"
	#
	# 	@grading['calculation'].each do |name, formula|
	# 		grade = calc_final_grade_formula(subs, formula)
	# 		if grade > 0
	# 			return grade
	# 		end
	# 	end
	# 	return 0
	# end
	
	# private

	def calc_final_grade_formula(subs, formula)
		total = 0
		total_weight = 0
		formula.each do |subtype, weight|
			log("    - #{subtype}")
			grade = calc_final_grade_subtype(subs, subtype)
			return 0 if grade == 0
			total += grade * weight
			total_weight += weight
		end
		
		return uva_round(total.to_f / total_weight.to_f)
	end
	
	private
	
	def uva_round(grade)
		return 5 if grade >= 4.75 && grade < 5.5
		return 6 if grade >= 5.5 && grade < 6.25
		return (2.0 * grade).round(0) / 2.0
	end
	
	def calc_final_grade_subtype(subs, subtype)
		return 0 if !@grading[subtype]['submits']

		total = 0
		total_weight = 0
		
		# case @grading[subtype]['type']
		# when 'pass'
		# 	allow_drop = @grading[subtype]['drop'] == 'any' ? 1 : 0
		# 	@grading[subtype]['submits'].each do |grade, weight|
		# 		log("        - grade")
		# 		return 0 if subs[grade].nil?
		# 		return 0 if @grading[subtype]['required'] == true && subs[grade].any_final_grade == 0
		# 		if subs[grade].any_final_grade == 0 && allow_drop >= 1
		# 			allow_drop -= 1
		# 		else
		# 			total += weight if subs[grade].any_final_grade < 0
		# 			total_weight += weight
		# 		end
		# 	end
		# 	return (1.0 + 9.0 * total / total_weight).round(1)
		# when 'percentage'
		# 	#
		# else
			droppable_grade = nil
			
			if (@grading[subtype]['drop'] == 'correctness')
				# raise "BUG"
				# droppable_grade = Grade.joins(:pset).where('grades.correctness >= 2').where('grades.id in (?)', subs.values).where('psets.name in (?)', @grading[subtype]['submits'].keys).order('grade asc, calculated_grade asc').first
			end
			
			grades = []
			
			if (@grading[subtype]['drop'] == 'scope')
				potential_drops = Grade.joins(:pset).where('grades.id in (?)', subs.values).where('psets.name in (?)', @grading[subtype]['submits'].keys).to_a
				# puts "DROPS"
				# potential_drops.each do |x| puts x.pset.name end
				potential_drops.keep_if { |a| a.subgrades[:scope] == 5 }
				# potential_drops.each do |x| puts x.pset.name end
				# droppable_grade = potential_drops.min { |a,b| a.any_final_grade <=> b.any_final_grade }
				grades = potential_drops.map { |d| calc_subtype_with_potential_drop(subs, subtype, @grading[subtype]['minimum'], d) }
			end
			
			grades << calc_subtype_with_potential_drop(subs, subtype, @grading[subtype]['minimum'], nil)
			
			# Rails.logger.debug "GRADES=#{grades}"
			
			# grade_with_drop = calc_subtype_with_potential_drop(subs, subtype, droppable_grade)
			# grade_without_drop = calc_subtype_with_potential_drop(subs, subtype, nil)

			# Rails.logger.debug [grade_with_drop, grade_without_drop].max
			# return [grade_with_drop, grade_without_drop].max
			log("        - final result: #{grades.max}")
			
			return grades.max
		# end
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
				real_weight = weight.shift # first element is weight
				log("              choosing from multiple: #{weight}")
				# get all grades for those assignments and take maximum, ignoring non-grades
				grade = weight.map { |grade_name| 
					if subs[grade_name]
						subs[grade_name].any_final_grade || 0
					else
						0
					end
				}.max
				log("                                    : #{grade}")

				log("max is 0") and return 0 if grade == 0
				total += grade * real_weight
				total_weight += real_weight
			else
			
				log("this grade is 0") and return 0 if subs[grade].nil? or subs[grade].any_final_grade.nil? or subs[grade].any_final_grade == 0
			
				if subs[grade] != droppable_grade
					total += subs[grade].any_final_grade * weight
					total_weight += weight
					# puts "including #{subs[grade].any_final_grade * weight}"
				end
			end
		end
		final = (1.0 * total / total_weight)
		log("            - result: #{final}")
		if !needs_minimum.present? or final >= needs_minimum
			return (1.0 * total / total_weight)
		else
			return 0
		end
	end
	
end
