module GradesHelper

    def some_time_or_never(time)
        time && time.to_formatted_s(:short) || "never"
    end

    def to_i_if_whole(number)
        number == number.to_i ? number.to_i : number
    end

    # a grade entered by hand overrules the one the formula calculates, exactly like
    # Grade#assigned_grade, which is what the site shows and what the final grade
    # calculation uses
    #
    def grade_for(submit)
        if submit
            submitted = submit[0]
            if submitted.grade and not (submitted.grade.calculated_grade.blank? && submitted.grade.grade.blank?)
                return submitted.grade.assigned_grade
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

    # Column headers in the grade entry grid get very little room, so a name
    # built out of several parts is shortened to the initial of every worded
    # part plus every number in full: vraag_1 -> V1, vraag_1_bonus -> V1B,
    # xx11 -> X11, deel_a -> D.A. Parts are split on anything that is not a
    # letter or a digit, and also where letters meet digits. A name of one
    # single part carries no structure to shorten, so it is left as it was.
    #
    def subgrade_header(name)
        parts = name.scan(/\d+|[[:alpha:]]+/)
        return name.capitalize if parts.size < 2

        parts.map { |part| part.match?(/\A\d/) ? part : part[0].upcase }.
            inject do |header, part|
                # two initials running together would read as one word; a number
                # beside a letter already shows where the break is
                joint = header.match?(/[[:alpha:]]\z/) && part.match?(/\A[[:alpha:]]/) ? "." : ""
                header + joint + part
            end
    end

    def translate_grade(grade)
        return t("grading.error") if grade.nil? || grade < -1
        return t("grading.sufficient") if grade == -1
        return t("grading.insufficient") if grade == 0
        return grade.to_s
    end

    def translate_subgrade(grade)
        return "" if grade.nil?
        return "NaN" if grade.is_a?(Float) and grade.nan?
        return t("grading.done_yes") if grade == -1 && !grade.is_a?(Float)
        return t("grading.done_no") if grade == 0
        return grade.to_i.to_s if grade == grade.to_i
        return grade.to_s
    end

    def grade_button(user, pset, submit, weight = nil, change = true, include_name = false)
        if submit
            if grade = submit.grade
                formatted_grade = grade.format(weight)
                link_to \
                    make_label(pset.name, formatted_grade, include_name),
                    submit,
                    class: "grade-button btn btn-sm #{'late' if submit.late?}",
                    data: { trigger: "modal", "turbo-frame" => "modal" }
            else
                link_to \
                    make_label(pset.name, "S", include_name),
                    submit,
                    class: "grade-button btn btn-sm #{'late' if submit.late?}",
                    data: { trigger: "modal", "turbo-frame" => "modal" }
            end
        else
            if current_user.senior?
                # this button is linked to the single form created in _table.html.erb
                button_tag \
                    form: "new_grade_form",
                    formaction: submits_path(submit: { pset_id: pset.id, user_id: user.id }),
                    class: "grade-button btn btn-sm btn-light auto-hide",
                    data: { "turbo-frame" => "modal", trigger: "modal", confirm: "Would you like to enter a grade for this unsubmitted pset?" } do
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
            retlabel = name[0, 3]
            retlabel += "<br>" + grade || "S"
        else
            retlabel = grade || "S"
        end
        return retlabel.html_safe
    end

    def grade_bg_type(grade)
        return "bg-light" if grade.blank? or !grade.public?

        if grade.type == :points
            case grade.assigned_grade
            when 0
                "bg-danger"
            when 1.., -1
                "bg-success"
            end
        end

        case grade.assigned_grade
        when 6.5..20.0, -1
            "bg-success"
        when 0..5.4
            "bg-danger"
        when "P"
            "bg-success"
        when "--", "S"
            "bg-light"
        else # -1
            "bg-warning"
        end
    end

    def format_form_contents(form_contents)
        tag.table(class: "table table-borderless") do
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
