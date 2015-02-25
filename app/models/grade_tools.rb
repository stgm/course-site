class GradeTools

	def initialize
		@grading = Settings['grading']
	end
	
	def calc_final_grade(subs)
		@grading['calculation'].each do |name, formula|
			grade = calc_final_grade_formula(subs, formula)
			if grade > 0
				return grade
			end
		end
		return 0
	end
	
	private

	def calc_final_grade_formula(subs, formula)
		total = 0
		total_weight = 0
		
		formula.each do |subtype, weight|
			grade = calc_final_grade_subtype(subs, subtype)
			return 0 if grade == 0
			total += grade * weight
			total_weight += weight
		end
		
		return uva_round(total.to_f / total_weight.to_f)
	end
	
	def uva_round(grade)
		return 5 if grade >= 4.75 && grade < 5.5
		return 6 if grade >= 5.5 && grade < 6.25
		return (2.0 * grade).round(0) / 2.0
	end
	
	def calc_final_grade_subtype(subs, subtype)
		puts subtype
		return 0 if !@grading[subtype]['grades']

		total = 0
		total_weight = 0
		
		case @grading[subtype]['type']
		when 'pass'
			allow_drop = @grading[subtype]['drop'] == 'any' ? 1 : 0
			@grading[subtype]['grades'].each do |grade, weight|
				return 0 if subs[grade].nil?
				# puts subs[grade].inspect
				# puts subs[grade][0]
				return 0 if @grading[subtype]['required'] == true && subs[grade].grade == 0
				if subs[grade].grade == 0 && allow_drop >= 1
					puts 'drop'
					allow_drop -= 1
				else
					total += weight if subs[grade].grade < 0
					total_weight += weight
				end
			end
			puts (1.0 + 9.0 * total / total_weight).round(1)
			return (1.0 + 9.0 * total / total_weight).round(1)
		when 'percentage'
			#
		else
			droppable_grade = nil
			if allow_drop = @grading[subtype]['drop'] == 'correctness' ? 1 : 0
				droppable_grade = User.first.grades.joins(:pset).where('psets.name in (?) and grades.correctness >= 2', Settings['grading']['psets']['grades'].keys).order('grade asc').first
			end
			
			@grading[subtype]['grades'].each do |grade, weight|
				return 0 if subs[grade].nil? or subs[grade].grade == 0
				if subs[grade] != droppable_grade
					puts "count: #{subs[grade].inspect}"
					total += subs[grade].grade * weight
					total_weight += weight
				end
			end
			puts (1.0 * total / total_weight).round(1)
			return (1.0 * total / total_weight).round(1)
		end
	end
	
end
