class GradeTools

	def self.available?
		!!Settings['grading'] && !!Settings['grading']['calculation']
	end

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
		return 0 if !@grading[subtype]['submits']
		Rails.logger.debug subs.inspect
		Rails.logger.debug subtype.inspect

		total = 0
		total_weight = 0
		
		case @grading[subtype]['type']
		when 'pass'
			allow_drop = @grading[subtype]['drop'] == 'any' ? 1 : 0
			@grading[subtype]['submits'].each do |grade, weight|
				return 0 if subs[grade].nil?
				return 0 if @grading[subtype]['required'] == true && subs[grade].any_final_grade == 0
				if subs[grade].any_final_grade == 0 && allow_drop >= 1
					allow_drop -= 1
				else
					total += weight if subs[grade].any_final_grade < 0
					total_weight += weight
				end
			end
			Rails.logger.debug (1.0 + 9.0 * total / total_weight).round(1)
			return (1.0 + 9.0 * total / total_weight).round(1)
		when 'percentage'
			#
		else
			droppable_grade = nil

			if (@grading[subtype]['drop'] == 'correctness')
				raise "BUG"
				droppable_grade = Grade.joins(:pset).where('grades.correctness >= 2').where('grades.id in (?)', subs.values).where('psets.name in (?)', @grading[subtype]['submits'].keys).order('grade asc, calculated_grade asc').first
			end

			if (@grading[subtype]['drop'] == 'scope')
				potential_drops = Grade.joins(:pset).where('grades.id in (?)', subs.values).where('psets.name in (?)', @grading[subtype]['submits'].keys).to_a
				potential_drops.keep_if { |a| a.subgrades[:scope] == 5 }
				droppable_grade = potential_drops.min { |a,b| a.any_final_grade <=> b.any_final_grade }
			end
			
			grade_with_drop = calc_subtype_with_potential_drop(subs, subtype, droppable_grade)
			grade_without_drop = calc_subtype_with_potential_drop(subs, subtype, nil)

			Rails.logger.debug [grade_with_drop, grade_without_drop].max
			return [grade_with_drop, grade_without_drop].max
		end
	end
	
	def calc_subtype_with_potential_drop(subs, subtype, droppable_grade)
		total = 0
		total_weight = 0
		@grading[subtype]['submits'].each do |grade, weight|
			return 0 if subs[grade].nil? or subs[grade].any_final_grade.nil? or subs[grade].any_final_grade == 0
			if subs[grade] != droppable_grade
				total += subs[grade].any_final_grade * weight
				total_weight += weight
			end
		end
		return (1.0 * total / total_weight)
	end
	
end
