module GradesHelper

	def grade_for(submit)
		if submit
			submitted = submit[0]
			if submitted.grade and not (submitted.grade.calculated_grade.blank? && submitted.grade.grade.blank?)
				return submitted.grade.calculated_grade || submitted.grade.grade
			end
		end
		
		return ""
	end
	
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
				is_public = submitted.grade.published?
				if not submitted.grade.grade.blank?
					grade_button_html(submitted, format_grade(submitted.grade.grade, pset.grade_type), is_public)
				else
					grade_button_html(submitted, format_grade(submitted.grade.calculated_grade, pset.grade_type), is_public)
				end
			else
				grade_button_html(submitted, 'S', false)
			end
		else
			# grade_button_html(user.id, pset.id, '--', 'Would you like to enter a grade for this unsubmitted pset?')
			link_to '--', submits_path(submit: { pset_id: pset.id, user_id: user.id }), method: :post, class: "btn btn-xs btn-block auto-hide", data: { confirm: 'Would you like to enter a grade for this unsubmitted pset?' }
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
		return 'btn-default' if not is_public
		case grade
		when -1, 6.5..10.0
			'btn-success'
		when 0..5.4
			'btn-danger'
		when "P"
			'btn-success'
		when "--", "S"
			'btn-grayed'
		else
			'btn-warning'
		end
	end
	
	def grade_button_html(submit_id, grade, is_public, confirmation=nil)
		if confirmation
			link_to grade, submit_grade_path(submit_id: submit_id), class: "btn btn-xs btn-block auto-hide #{ grade_button_type(grade, is_public) }", data: { confirm:confirmation }
		else
			link_to grade, submit_grade_path(submit_id: submit_id), class: "btn btn-xs btn-block #{ grade_button_type(grade, is_public) }"
		end
	end
	
end
