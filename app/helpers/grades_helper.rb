module GradesHelper
	
	def color_for_filename(filename, potential)
		potential.include?(filename) && 'text-success' || 'text-danger'
	end

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
	
	def grade_button(user, pset, subs, name=true)
		if subs[pset.id] && submit = subs[pset.id][0]
			if grade = submit.grade
				type = grade_button_type(make_label(submit.pset_name, grade.any_final_grade), grade.public?)
				link_to make_label(submit.pset_name, grade.any_final_grade), submit_path(id: submit.id), class: "btn btn-sm flex-fill auto-hide #{type}", title: submit.pset_name, data: { toggle:"tooltip", placement:"top" }
			else
				link_to make_label(submit.pset_name, "S"), submit_path(id: submit.id), class: "btn btn-sm flex-fill btn-light auto-hide", title:submit.pset_name, data: { toggle:"tooltip", placement:"top" }
			end
		else
			link_to make_label(pset.name, "--"), submits_path(submit: { pset_id: pset.id, user_id: user.id }), method: :post, class: "btn btn-sm flex-fill btn-light auto-hide", data: { confirm: 'Would you like to enter a grade for this unsubmitted pset?' }
		end
	end
	
	def make_label(name, grade, use_name=true)
		retlabel = name 
		retlabel += "<br>" + grade.to_s || 'S'
		return retlabel.html_safe
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
		return 'btn-light' if not is_public
		case grade
		when -1, 6.5..10.0
			'btn-success'
		when 0..5.4
			'btn-danger'
		when "P"
			'btn-success'
		when "--", "S"
			'btn-light'
		else
			'btn-warning'
		end
	end
	
end
