module GradesHelper
	
	def translate_grade(grade)
		return "error" if grade.nil? or grade < -1
		return "pass" if grade == -1
		return "fail" if grade == 0
		return grade.to_s
	end
	
	def grade_button(user, pset)
		subs = user.submits.group_by(&:pset_id)
		if subs[pset.id]
			submitted = subs[pset.id][0]
			if submitted.graded?
				grade_button_html(user.id, pset.id, submitted.grade.grade)
			else
				grade_button_html(user.id, pset.id, 'S')
			end
		else
			grade_button_html(user.id, pset.id, '--', 'Would you like to enter a grade for this unsubmitted pset?')
		end
	end
	
	def grade_button_type(grade)
		case grade
		when 5.5..10.0
			'btn-success'
		when "P"
			'btn-success'
		when "--"
			'btn-default'
		else
			'btn-danger'
		end
	end
	
	def grade_button_html(user_id, pset_id, grade, confirmation=nil)
		if confirmation
			link_to grade, grade_form_path(user_id: user_id, pset_id: pset_id), class: "btn btn-xs btn-block auto-hide #{ grade_button_type(grade) }", data: { confirm:confirmation }
		else
			link_to grade, grade_form_path(user_id: user_id, pset_id: pset_id), class: "btn btn-xs btn-block #{ grade_button_type(grade) }"
		end
	end
	
end
