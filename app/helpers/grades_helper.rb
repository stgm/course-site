module GradesHelper
	
	# def calculate_grade(grade)
	# 	return nil if Settings['grading'].nil?
	# 	f = Settings['grading']['formulas']
	# 	return nil if f.nil?
	# 	pset_name = grade.pset.name
	# 	return nil if f[pset_name].nil?
	# 	begin
	# 		cg = grade.instance_eval(f[pset_name])
	# 	rescue
	# 		cg = nil
	# 	end
	# 	return cg
	# end
	
	def translate_grade(grade)
		return "error" if grade.nil? or grade < -1
		return "pass" if grade == -1
		return "fail" if grade == 0
		return grade.to_s
	end
	
	def grade_button(user, pset, subs)
		if subs[pset.id]
			submitted = subs[pset.id][0]
			if submitted.graded?
				is_public = submitted.grade['public']
				if not submitted.grade.grade.blank?
					grade_button_html(user.id, pset.id, format_grade(submitted.grade.grade, pset.grade_type), is_public)
				else
					grade_button_html(user.id, pset.id, format_grade(submitted.grade.calculated_grade, pset.grade_type), is_public)
				end
			else
				grade_button_html(user.id, pset.id, 'S', false)
			end
		else
			grade_button_html(user.id, pset.id, '--', 'Would you like to enter a grade for this unsubmitted pset?')
		end
	end
	
	def format_grade(grade, type)
		case type
		when 'float'
			return grade
		else # integer, pass
			return grade.to_i
		end
	end
	
	def grade_button_type(grade, is_public)
		return 'btn-grayed' if not is_public
		case grade
		when -1, 5.5..10.0
			'btn-success'
		when 0
			'btn-danger'
		when "P"
			'btn-success'
		when "--", "S"
			'btn-default'
		else
			'btn-warning'
		end
	end
	
	def grade_button_html(user_id, pset_id, grade, is_public, confirmation=nil)
		if confirmation
			link_to grade, grade_form_path(user_id: user_id, pset_id: pset_id), class: "btn btn-xs btn-block auto-hide #{ grade_button_type(grade, is_public) }", data: { confirm:confirmation }
		else
			link_to grade, grade_form_path(user_id: user_id, pset_id: pset_id), class: "btn btn-xs btn-block #{ grade_button_type(grade, is_public) }"
		end
	end
	
end
