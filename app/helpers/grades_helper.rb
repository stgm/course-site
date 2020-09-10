module GradesHelper
	
	def some_time_or_never(time)
		time && time.to_formatted_s(:short) || "never"
	end
	
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

	def formatted_submit_name(submit)
		return submit.titleize.gsub(/([^\d\s])(\d)/, '\1 \2')
	end
	
	def subgrade_for(submit, subgrade)
		if submit
			submitted = submit[0]
			if submitted.grade
				return submitted.grade.subgrades[subgrade]
			end
		end
		
		return ""
	end
	
	def translate_grade(grade)
		return "error" if grade.nil? || grade < -1
		return "pass" if grade == -1
		return "fail" if grade == 0
		return grade.to_s
	end

	def translate_subgrade(grade)
		return "" if grade.nil?
		return "yes" if grade == -1 && !grade.is_a?(Float)
		return "no" if grade == 0
		return grade.to_i.to_s if grade == grade.to_i
		return grade.to_s
	end
	
	def grade_button(user, pset, subs, change=true)
		if !change
			type=''
			if subs[pset.id] && submit = subs[pset.id][0]
				if grade = submit.grade
					type = grade_button_type(grade.any_final_grade, grade.public?)
					label = make_label(pset.name, subs[pset.id] && subs[pset.id][0].grade ? subs[pset.id][0].grade.any_final_grade : "--")
				else
					label = make_label(pset.name, "S")
				end
			else
				label = make_label(pset.name, "--")
			end
			return tag.div(class: "btn btn-sm flex-fill #{type}") do
				label
			end
		end
		
		if subs[pset.id] && submit = subs[pset.id][0]
			if grade = submit.grade
				type = grade_button_type(grade.any_final_grade, grade.public?)
				link_to make_label(pset.name, grade.any_final_grade), submit, remote: true, class: "btn btn-sm flex-fill #{type}", data: { trigger: 'modal' }
			else
				link_to make_label(pset.name, "S"), submit, remote: true, class: "btn btn-sm flex-fill btn-light", data: { trigger: 'modal' }
			end
		else
			link_to make_label(pset.name, "--"), submits_path(submit: { pset_id: pset.id, user_id: user.id }), method: :post, remote: true, class: "btn btn-sm flex-fill btn-light auto-hide", data: { trigger: 'modal', confirm: 'Would you like to enter a grade for this unsubmitted pset?' }
		end
	end
	
	def make_label(name, grade, use_name=true)
		retlabel = name[0,3]
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
		when 10.0001..20
			'btn-dark'
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
	
	def format_form_contents(form_contents)
		tag.table(class: 'table') do
			form_contents.collect do |form_field, field_value|
				concat(
					tag.tr do
						tag.td(form_field) + tag.td(field_value)
					end
				)
			end
		end
	end
	
end
