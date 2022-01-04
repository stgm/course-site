module User::FinalGradeCalculator
    def self.run_for(user_grade_list)
        # tries to calculate all kinds of final grades

        grades = {}
        GradingConfig.calculation.each do |name, parts|
            grades[name] = final_grade_from_partial_grades(parts, user_grade_list)
        end

        return grades # { final: '6.0', resit: '0.0' }
    end

    def self.final_grade_from_partial_grades(config, user_grade_list)
        # attempt to calculate each partial grade
        weighted_partial_grades = config.collect do |partial_name, weight|
            partial_config = GradingConfig.all[partial_name]
            [partial_name, average_grade_from_submits(partial_config, user_grade_list), weight]
        end

        # if any of the partial grades has failed, propagate this result immediately
        partial_grades = weighted_partial_grades.map{|g| g[1]}
        return :not_attempted if partial_grades.include? :not_attempted
        return :missing_data  if partial_grades.include? :missing_data
        return :insufficient  if partial_grades.include? :insufficient

        return uva_round(calculate_average(weighted_partial_grades))
    end

    def self.average_grade_from_submits(config, user_grade_list)
        # config := { need_attempt: true, minimum: 5.5, required: true, drop: :lowest, submits: { m1: 1, m2: 2, ... } }
        grades = collect_grades_from_submits(config['submits'], user_grade_list)
        grades = remove_unused_bonus(grades)

        # missing data for something like an exam receives a "not attempted" note
        return :not_attempted if config['attempt_required'] && missing_data?(grades)

        # missing data means we can't calculate any average
        return :missing_data if missing_data?(grades)

        # zeroed data for something like tests receives an "insufficient"
        return :insufficient if config['required'] && zeroed_data?(grades)

        grades = drop_lowest_from(grades) if config['drop'] == :lowest
        average = calculate_average(grades)

        # two similar kinds of "insufficient", one for minimum grade, and one for failed tests
        return :insufficient if config['minimum'] && average < config['minimum']

        return average
    end

    def self.collect_grades_from_submits(config, user_grade_list)
        grades = config.collect do |grade_name, weight|
            # if no user_grade_list[grade_name] exists this will enter 'nil' into the resulting array
            grade = user_grade_list[grade_name] && user_grade_list[grade_name].any_final_grade
            [grade_name, grade, weight]
        end
    end

    def self.missing_data?(grades)
        # any of the grades are missing
        grades.select{|g| g[1]==nil }.any?
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
        if has_bonus?(grades)
            # bonus calculation assumes equals weights for all grades!
            total = grades.map{|g| g[1]}.sum
            weight = grades.map{|g| g[2]}.reject{|w| w == :bonus}.sum
        else
            # multiply each grade by its weight
            total = grades.inject(0) { |total, (name, grade, weight)| total += grade * weight }
            weight = grades.map{|g| g[2]}.sum
        end

        # ensure float divide
        avg = total.to_f / weight
        # if the average is a -1, "everything passed", so reinterpret as a 10
        return avg == -1.0 && 10 || avg
    end

    def self.has_bonus?(grades)
        grades.select{|g| g[2] == :bonus}.any?
    end

    def self.remove_unused_bonus(grades)
        grades.reject{|g| (g[1] == nil || g[1] == 0) && g[2] == :bonus}
    end

    def self.uva_round(grade)
        return 5 if grade >= 4.75 && grade < 5.5
        return 6 if grade >= 5.5 && grade < 6.25
        return 10 if grade > 10
        return (2.0 * grade).round(0) / 2.0
    end
end
