# NOTE: this is not included into User, but directly exposes module methods instead

module User::FinalGradeCalculator
    def self.run_for(grading_config, user_grade_list)
        # tries to calculate all kinds of final grades

        grades = {}
        grading_config.calculation.each do |name, relevant_parts|
            grades[name] = final_grade_from_partial_grades(grading_config, relevant_parts, user_grade_list)
        end

        return grades # { final: '6.0', resit: '0.0' }
    end

    def self.final_grade_from_partial_grades(grading_config, relevant_parts, user_grade_list)
        # attempt to calculate each partial grade
        weighted_partial_grades = relevant_parts.collect do |partial_name, weight|
            partial_config = grading_config.components[partial_name]
            if partial_config['type'] == 'points'
                [partial_name, grade_from_points_from_submits(partial_config, user_grade_list), weight]
            elsif partial_config['type'] == 'maximum'
                [partial_name, maximum_grade_from_submits(partial_config, user_grade_list), weight]
            else
                [partial_name, average_grade_from_submits(partial_config, user_grade_list), weight]
            end
        end

        # if any of the partial grades has failed, propagate this result immediately
        partial_grades = weighted_partial_grades.map{|g| g[1]}
        return :not_attempted if partial_grades.include? :not_attempted
        return :missing_data  if partial_grades.include? :missing_data
        return :insufficient  if partial_grades.include? :insufficient

        return uva_round(calculate_average(weighted_partial_grades))
    end

    # calculate subgrade based on per-assignment points
    def self.grade_from_points_from_submits(config, user_grade_list)
        grades = collect_grades_from_submits(config['submits'], user_grade_list)

        if config['attempt_required'] && missing_data?(grades)
            return :not_attempted
        end

        potential = get_points_potential(grades, config['maximum'])
        total = get_points_total(grades)
        grade = points_to_grade(total, potential)

        if config['minimum'] && grade < config['minimum']
            return :insufficient
        end

        return grade
    end

    def self.get_points_potential(grades, config)
        if config.present?
            return config
        else
            return grades.map(&:third).sum
        end
    end

    def self.get_points_total(grades)
        grades = fill_missing(grades, 0)
        grades.map do |g|
            if g[1] == -1
                # pass means they get full credit
                g[2]
            else
                # or if a number of points was entered by grader, we use that
                g[1]
            end
        end.sum
    end

    def self.points_to_grade(points, potential_points)
        proportion = points / potential_points.to_f
        grade = proportion * 9 + 1
        # if total and potential are both 0 we get NaN
        grade = 0 if grade.nan?
        return grade
    end

    def self.maximum_grade_from_submits(config, user_grade_list)
        grades = collect_grades_from_submits(config['submits'], user_grade_list)

        # if some of the assignments were not handed in or graded, we
        # do not allow this strategy to produce a grade (fill in 0 as
        # a grade to make it work)
        if missing_data?(grades)
            return :missing_data
        end

        max_grade = grades.max{|g1, g2| g1[1] <=> g2[1]}
        grade = max_grade[1]

        # add any bonus grades
        if config['bonus'].present?
            bonuses = collect_grades_from_submits(config['bonus'], user_grade_list)
            grade += total_bonus(bonuses)
            grade = [10, grade].min
        end

        if config['minimum'] && average < config['minimum']
            return :insufficient
        end

        return grade
    end
    
    def self.average_grade_from_submits(config, user_grade_list)
        grades = collect_grades_from_submits(config['submits'], user_grade_list)

        # missing data for something like an exam receives a "not attempted" note
        return :not_attempted if config['attempt_required'] && missing_data?(grades)

        # deal with missing data: if allowed, fill with default; else immediately cancel
        if missing_data?(grades) && config['fill_missing'].present?
            grades = fill_missing(grades, config['fill_missing'])
        elsif missing_data?(grades)
            return :missing_data
        end

        # zeroed data for something like tests receives an "insufficient"
        return :insufficient if config['required'] && zeroed_data?(grades)

        grades = drop_lowest_from(grades) if config['drop'] == :lowest
        grade = calculate_average(grades)

        # add any bonus grades
        if config['bonus'].present?
            bonuses = collect_grades_from_submits(config['bonus'], user_grade_list)
            grade += total_bonus(bonuses)
            grade = [10, grade].min
        end

        # two similar kinds of "insufficient", one for minimum grade, and one for failed tests
        if config['minimum'] && grade < config['minimum']
            return :insufficient
        end

        return grade
    end

    def self.total_bonus(grades)
        # remove any zero/non grades from the bonus list
        bonuses = grades.reject{|g| g[1] == nil || g[1] == 0}

        # sum all and add to grade
        count_bonuses = bonuses.map do |g|
            if g[1] == -1
                # in case of a "pass" just add the weight from grading.yml
                g[2]
            else
                g[1] * g[2]
            end
        end
        
        return count_bonuses.sum
    end

    def self.collect_grades_from_submits(config, user_grade_list, **kwargs)
        grades = config.collect do |grade_name, weight|
            # if no user_grade_list[grade_name] exists this will enter 'nil' into the resulting array
            grade = user_grade_list[grade_name] && user_grade_list[grade_name].assigned_grade
            grade = convert_pass_to_10(grade) if kwargs.key?(:convert_pass_to_10)
            [grade_name, grade, weight]
        end
    end

    def self.convert_pass_to_10(grade)
        if grade == -1
            return 10
        else
            return grade
        end
    end

    def self.missing_data?(grades)
        # any of the grades are missing
        grades.select{|g| g[1]==nil }.any?
    end

    def self.fill_missing(grades, value)
        grades.map do |g|
            if g[1].blank?
                [g[0], value, g[2]]
            else
                [g[0], g[1], g[2]]
            end
        end
    end

    def self.zeroed_data?(grades)
        # any of the grades are zeroed
        grades.select{|g| g[1]==0 }.any?
    end

    def self.drop_lowest_from(grades)
        # only removes lowest if there is more than 1 grade
        return grades if grades.length <= 1
        min = grades.min { |x,y| x[1] <=> y[1] }
        grades.delete(min)
        grades
    end

    def self.calculate_average(grades)
        # multiply each grade by its weight
        total = grades.inject(0) { |total, (name, grade, weight)| total += grade * weight }
        weight = grades.map{|g| g[2]}.sum
        return total.to_f / weight
    end

    def self.uva_round(grade)
        return 5 if grade >= 4.75 && grade < 5.5
        return 6 if grade >= 5.5 && grade < 6.25
        return 10 if grade > 10
        return (2.0 * grade).round(0) / 2.0
    end
end
