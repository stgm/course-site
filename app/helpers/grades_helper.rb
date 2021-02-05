module GradesHelper

	def some_time_or_never(time)
		time && time.to_formatted_s(:short) || "never"
	end

	# def color_for_filename(filename, potential)
	# 	potential.include?(filename) && 'text-success' || 'text-danger'
	# end

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
		return "fout" if grade.nil? || grade < -1
		return "voldoende" if grade == -1
		return "onvoldoende" if grade == 0
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
		if subs[pset.id] && submit = subs[pset.id][0]
			if grade = submit.grade
				# type = grade_button_type(grade.any_final_grade, grade.public?)
				type=''
				link_to make_label(pset.name, grade.format), submit, class: "grade-button btn btn-sm #{type}", data: { trigger: 'modal', 'turbo-frame' => 'modal' }
			else
				link_to make_label(pset.name, "S"), submit, class: "grade-button btn btn-sm btn-light", data: { trigger: 'modal', 'turbo-frame' => 'modal' }
			end
		else
			if current_user.senior?
				button_to \
					submits_path(submit: { pset_id: pset.id, user_id: user.id }),
					method: :post,
					class: "grade-button btn btn-sm btn-light auto-hide",
					data: { trigger: 'modal', confirm: 'Would you like to enter a grade for this unsubmitted pset?' },
					form: { class: 'd-inline', data: { 'turbo-frame' => 'modal' } } do
						make_label(pset.name, "--")
					end
			else
				tag.div(class: "grade-button btn btn-sm #{type}") do
					make_label(pset.name, "--")
				end
			end
		end
	end

	def make_label(name, grade)
		retlabel = name[0,3]
		retlabel += "<br>" + grade || 'S'
		retlabel = grade || 'S'
		return retlabel.html_safe
	end

	def grade_button_type(grade, is_public)
		return 'btn-light' if not is_public
		case grade
		when 10.0001..20
			'btn-dark'
		when 6.5..10.0
			'btn-success'
		when 0..5.4
			'btn-danger'
		when "P"
			'btn-success'
		when "--", "S"
			'btn-light'
		else # -1
			'btn-warning'
		end
	end

	def grade_bg_type(grade, is_public)
		return 'bg-light' if not is_public
		case grade
		when 10.0001..20
			'bg-dark'
		when 6.5..10.0
			'bg-success'
		when 0..5.4
			'bg-danger'
		when "P"
			'bg-success'
		when "--", "S"
			'bg-light'
		else # -1
			'bg-warning'
		end
	end

	def format_form_contents(form_contents)
		tag.table(class: 'table table-borderless') do
			form_contents.collect do |form_field, field_value|
				concat(
					tag.tr do
						tag.td(tag.strong(form_field)) + tag.td(field_value)
					end
				)
			end
		end
	end

end
