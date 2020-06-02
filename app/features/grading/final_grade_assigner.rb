module Grading::FinalGradeAssigner

	def self.available?
		!!Settings['grading'] && !!Settings['grading']['calculation']
	end

	def self.assign_final_grade(student, grader)
		grades = Grading::FinalGradeCalculator.run_for(student.all_submits)
		grades.each do |name, grade|
			grade = number_grade(grade)
			if grade.present? # there really is an assignable grade
				
				# find the submit and grade object
				final = student.submits.where(pset:Pset.where(name: name).first).first_or_create
				final.create_grade if !final.grade
				
				# only change if grade hasn't been published yet
				if not ['published', 'exported'].include?(final.grade.status)
					final.grade.grade = grade

					# only if the grade is different from before we go through
					if final.grade.grade_changed?
						final.grade.grader = grader
						final.grade.status = Grade.statuses['finished']
						final.grade.save
					end
				end
			end
		end
	end

	def self.number_grade(grade)
		case grade
		when :not_attempted
			# something like an exam hadn't been attempted
			return nil
		when :missing_data
			# anything that must have been attempted, was, but something else is missing
			return nil
		when :insufficient
			# some tests have been failed
			return 0
		else
			return grade
		end
	end

end
