module GradesHelper

	def some_time_or_never(time)
		time && time.to_formatted_s(:short) || "never"
	end

    def to_i_if_whole(number)
        number == number.to_i ? number.to_i : number
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
		return t("grading.error") if grade.nil? || grade < -1
		return t("grading.sufficient") if grade == -1
		return t("grading.insufficient") if grade == 0
		return grade.to_s
	end

	def translate_subgrade(grade)
		return "" if grade.nil?
		return t("grading.done_yes") if grade == -1 && !grade.is_a?(Float)
		return t("grading.done_no") if grade == 0
		return grade.to_i.to_s if grade == grade.to_i
		return grade.to_s
	end

	def grade_button(user, pset, submit, change=true, include_name=false)
		if submit
			if grade = submit.grade
				link_to \
					make_label(pset.name, grade.format, include_name),
					submit,
					class: "grade-button btn btn-sm #{'late' if submit.late?}",
					data: { trigger: 'modal', 'turbo-frame' => 'modal' }
			else
				link_to \
					make_label(pset.name, "S", include_name),
					submit,
					class: "grade-button btn btn-sm #{'late' if submit.late?}",
					data: { trigger: 'modal', 'turbo-frame' => 'modal' }
			end
		else
			if current_user.senior?
				button_to \
					submits_path(submit: { pset_id: pset.id, user_id: user.id }),
					method: :post,
					class: "grade-button btn btn-sm btn-light auto-hide",
					data: { trigger: 'modal', confirm: 'Would you like to enter a grade for this unsubmitted pset?' },
					form: { class: 'd-inline', data: { 'turbo-frame' => 'modal' } } do
						make_label(pset.name, "--", include_name)
					end
			else
				tag.div(class: "grade-button btn btn-sm") do
					make_label(pset.name, "--", include_name)
				end
			end
		end
	end

	def make_label(name, grade, include_name)
		if include_name
			retlabel = name[0,3]
			retlabel += "<br>" + grade || 'S'
		else
			retlabel = grade || 'S'
		end
		return retlabel.html_safe
	end

	def grade_bg_type(grade)
		return 'bg-light' if grade.blank? or !grade.public?
		case grade.assigned_grade
		when 6.5..20.0, -1
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
						if field_value.include?("\n  ")
							tag.td(tag.strong(form_field)) + tag.td(tag.pre(field_value))
						else
							tag.td(tag.strong(form_field)) + tag.td(simple_format(field_value))
						end
					end
				)
			end
		end
	end

end
