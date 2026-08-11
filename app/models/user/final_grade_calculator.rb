# NOTE: this is not included into User, but directly exposes module methods instead

class User::FinalGradeCalculator

    # a pass is the value -1 throughout this codebase, see Grade::Formatter
    PASS = -1
    # and -2 is a resubmit exception, which is not a grade at all
    RESUBMIT_EXCEPTION = -2
    # the lowest numeric grade that counts as a pass, like Grade#sufficient?
    SUFFICIENT = 5.5

    # how a component turns its assignment grades into a component grade; anything
    # without a type of its own is an average
    STRATEGIES = {
        "points"     => :grade_from_points_from_submits,
        "maximum"    => :maximum_grade_from_submits,
        "pass_all"   => :pass_all_from_submits,
        "pass_any"   => :pass_any_from_submits,
        "pass_first" => :pass_first_from_submits,
        "pass_last"  => :pass_last_from_submits,
        "average"    => :average_grade_from_submits
    }.freeze

    # A calculated result in words, for the internal notes on a final grade. A pass/fail
    # result reads better as "sufficient" than as the v and x the grade columns show.
    def self.result_word(value)
        case value
        when PASS then I18n.t("grading.sufficient")
        when 0    then I18n.t("grading.insufficient")
        else value.to_s
        end
    end

    def self.graded_on(grade)
        on_date(grade.updated_at)
    end

    # a note that is read months later needs the year, and a day without a leading zero
    def self.on_date(time)
        time.strftime("%-d %B %Y")
    end

    def initialize(grading_config)
        @grading_config = grading_config
        @debug = []
    end

    def run(user_grade_list)
        # tries to calculate all kinds of final grades

        grades = {}
        notes = {}
        @grading_config.calculation.each do |name, spec|
            # notes are per final grade: they end up on that one grade, and a resit says
            # something a first registration does not
            @debug = [ "#{name} #{DateTime.current}" ]
            @deciding = nil
            @superseded = []

            grades[name] = final_grade_from_partial_grades(spec, user_grade_list)
            notes[name] = attempt_lines(name) + @debug
        end

        grades["_debug"] = notes

        return grades # { final: '6.0', resit: '0.0' }
    end

    # Which attempt a resit came out of, and which earlier attempt it replaced. Only a
    # pass_last component skips over anything, so this is empty for everything else.
    def attempt_lines(final_name)
        return [] if @superseded.blank?

        name, grade = @deciding
        lines = [ I18n.t("grading.attempt_note.based_on",
            date: self.class.on_date(Date.current), name: final_name, attempt: name,
            result: self.class.result_word(grade.assigned_grade),
            graded: self.class.graded_on(grade)) ]

        @superseded.each do |previous_name, previous_grade|
            lines << I18n.t("grading.attempt_note.overwritten",
                attempt: previous_name,
                result: self.class.result_word(previous_grade.assigned_grade),
                graded: self.class.graded_on(previous_grade))
        end

        lines
    end

    def final_grade_from_partial_grades(spec, user_grade_list)
        # attempt to calculate each partial grade
        weighted_partial_grades = spec["components"].collect do |partial_name, weight|
            partial_config = @grading_config.components[partial_name]
            strategy = STRATEGIES.fetch(partial_config["type"], :average_grade_from_submits)
            res = send(strategy, partial_config, user_grade_list)
            @debug << "- #{partial_name}: #{strategy} -> #{res}"
            [ partial_name, res, weight ]
        end

        partial_grades = weighted_partial_grades.map { |g| g[1] }

        # if any of the partial grades has failed, propagate this result immediately. A
        # component that has nothing to report yet comes first: no grade is registered at
        # all then, not even a failing one
        return :not_attempted if partial_grades.include? :not_attempted
        return :missing_data  if partial_grades.include? :missing_data
        return :insufficient  if partial_grades.include? :insufficient

        # a pass/fail final grade is not weighed: every component has to be a pass
        if spec["type"] == "pass"
            return PASS if partial_grades.all? { |grade| grade == PASS }
            return :insufficient
        end

        return uva_round(calculate_average(weighted_partial_grades))
    end

    # calculate subgrade based on per-assignment points
    def grade_from_points_from_submits(config, user_grade_list)
        grades = collect_grades_from_submits(config["submits"], user_grade_list)

        # if any specified grade has weight 0 it should be required,
        # thus yields lowest grade if not present
        if grades.select { |name, grade, weight| weight == 0 && (grade.nil? || grade == 0) }.present?
            return 1
        end

        if config["attempt_required"] && missing_data?(grades)
            return :not_attempted
        end

        potential = get_points_potential(grades, config["maximum"])
        total = get_points_total(grades, config["maximum"])
        grade = points_to_grade(total, potential)

        if config["minimum"] && grade < config["minimum"]
            return :insufficient
        end

        return grade
    end

    def get_points_potential(grades, maximum)
        base_points = grades.map(&:third).sum
        if maximum.present?
            return [maximum, base_points].min
        else
            return base_points
        end
    end

    def get_points_total(grades, maximum)
        grades = fill_missing(grades, 0)
        base_points = grades.map do |g|
            if g[1] == PASS
                # pass means they get full credit
                g[2]
            else
                # or if a number of points was entered by grader, we use that
                g[1]
            end
        end.sum
        if maximum.present?
            return [maximum, base_points].min
        else
            return base_points
        end
    end

    def points_to_grade(points, potential_points)
        proportion = points / potential_points.to_f
        grade = proportion * 9 + 1
        # if total and potential are both 0 we get NaN
        grade = 0 if grade.nan?
        return grade
    end

    def maximum_grade_from_submits(config, user_grade_list)
        grades = collect_grades_from_submits(config["submits"], user_grade_list)

        # if some of the assignments were not handed in or graded, we
        # do not allow this strategy to produce a grade (fill in 0 as
        # a grade to make it work)
        if missing_data?(grades)
            return :missing_data
        end

        max_grade = grades.max { |g1, g2| g1[1] <=> g2[1] }
        grade = max_grade[1]

        # add any bonus grades
        if config["bonus"].present?
            bonuses = collect_grades_from_submits(config["bonus"], user_grade_list)
            grade += total_bonus(bonuses)
            grade = [ 10, grade ].min
        end

        if config["minimum"] && average < config["minimum"]
            return :insufficient
        end

        return grade
    end

    def average_grade_from_submits(config, user_grade_list)
        grades = collect_grades_from_submits(config["submits"], user_grade_list)

        # missing data for something like an exam receives a "not attempted" note
        return :not_attempted if config["attempt_required"] && missing_data?(grades)

        # deal with missing data: if allowed, fill with default; else immediately cancel
        if missing_data?(grades) && config["fill_missing"].present?
            grades = fill_missing(grades, config["fill_missing"])
        elsif missing_data?(grades)
            return :missing_data
        end

        # zeroed data for something like tests receives an "insufficient"
        return :insufficient if config["required"] && zeroed_data?(grades)

        grades = drop_lowest_from(grades) if config["drop"] == :lowest
        grade = calculate_average(grades)

        # add any bonus grades
        if config["bonus"].present?
            bonuses = collect_grades_from_submits(config["bonus"], user_grade_list)
            grade += total_bonus(bonuses)
            grade = [ 10, grade ].min
        end

        # two similar kinds of "insufficient", one for minimum grade, and one for failed tests
        if config["minimum"] && grade < config["minimum"]
            return :insufficient
        end

        return grade
    end

    # every assignment has to be passed. A failed assignment is a definitive result,
    # an ungraded one only means the component is not decided yet
    def pass_all_from_submits(config, user_grade_list)
        grades = collect_grades_from_submits(config["submits"], user_grade_list).map(&:second)

        return :insufficient  if grades.any? { |grade| failed?(grade) }
        return :not_attempted if grades.any? { |grade| !passed?(grade) }

        return PASS
    end

    # one passed assignment is enough. As long as nothing has been graded at all there
    # is no verdict, because the remaining attempts are still to come
    def pass_any_from_submits(config, user_grade_list)
        grades = collect_grades_from_submits(config["submits"], user_grade_list).map(&:second)

        return PASS if grades.any? { |grade| passed?(grade) }
        return :not_attempted if grades.none? { |grade| failed?(grade) }

        return :insufficient
    end

    # The first exam attempt a student made decides the first registration, so this is the
    # component to put in the final grade a course is registered under.
    def pass_first_from_submits(config, user_grade_list)
        attempts = attempts_made(config, user_grade_list)

        # nothing sat means nothing to register, which is not the same as a fail
        return :not_attempted if attempts.empty?

        decided_by attempts.first, []
    end

    # Every attempt after the first belongs to the resit registration, and the most recent
    # of them decides it. Anything in between it and the first attempt is overwritten, which
    # the note on the grade records.
    def pass_last_from_submits(config, user_grade_list)
        attempts = attempts_made(config, user_grade_list)

        # one attempt is the first registration; there is no resit to register
        return :not_attempted if attempts.size < 2

        decided_by attempts.last, attempts[1..-2].reverse
    end

    # The attempts a student actually made, in the order the component lists them. An
    # assignment counts as an attempt once it has a grade with a value, pass or fail; a
    # resubmit exception is not a result. The order is the configured one rather than the
    # order of the dates, so which attempt counts as the first does not change when a
    # grader enters an earlier one late.
    def attempts_made(config, user_grade_list)
        config["submits"].keys.filter_map do |name|
            grade = user_grade_list[name]
            value = grade&.assigned_grade
            next if value.nil? || value == RESUBMIT_EXCEPTION
            [ name, grade ]
        end
    end

    # remembers which attempt the component came out of, for the note on the final grade
    def decided_by(attempt, superseded)
        @deciding = attempt
        @superseded = superseded

        passed?(attempt.second.assigned_grade) ? PASS : :insufficient
    end

    def passed?(grade)
        grade == PASS || (grade.present? && grade >= SUFFICIENT)
    end

    # a resubmit exception is not a grade, so it does not fail anything
    def failed?(grade)
        grade.present? && grade != RESUBMIT_EXCEPTION && !passed?(grade)
    end

    def total_bonus(grades)
        # remove any zero/non grades from the bonus list
        bonuses = grades.reject { |g| g[1] == nil || g[1] == 0 }

        # sum all and add to grade
        count_bonuses = bonuses.map do |g|
            if g[1] == PASS
                # in case of a "pass" just add the weight from grading.yml
                g[2]
            else
                g[1] * g[2]
            end
        end

        return count_bonuses.sum
    end

    def collect_grades_from_submits(config, user_grade_list, **kwargs)
        grades = config.collect do |grade_name, weight|
            # if no user_grade_list[grade_name] exists this will enter 'nil' into the resulting array
            grade = user_grade_list[grade_name] && user_grade_list[grade_name].assigned_grade
            grade = convert_pass_to_10(grade) if kwargs.key?(:convert_pass_to_10)
            [ grade_name, grade, weight ]
        end
    end

    def convert_pass_to_10(grade)
        if grade == PASS
            return 10
        else
            return grade
        end
    end

    def missing_data?(grades)
        # any of the grades are missing
        grades.select { |g| g[1]==nil }.any?
    end

    def fill_missing(grades, value)
        grades.map do |g|
            if g[1].blank?
                [ g[0], value, g[2] ]
            else
                [ g[0], g[1], g[2] ]
            end
        end
    end

    def zeroed_data?(grades)
        # any of the grades are zeroed
        grades.select { |g| g[1]==0 }.any?
    end

    def drop_lowest_from(grades)
        # only removes lowest if there is more than 1 grade
        return grades if grades.length <= 1
        min = grades.min { |x, y| x[1] <=> y[1] }
        grades.delete(min)
        grades
    end

    def calculate_average(grades)
        # multiply each grade by its weight
        total = grades.inject(0) { |total, (name, grade, weight)| total += grade * weight }
        weight = grades.map { |g| g[2] }.sum
        return total.to_f / weight
    end

    def uva_round(grade)
        return 5 if grade >= 4.75 && grade < 5.5
        return 6 if grade >= 5.5 && grade < 6.25
        return 10 if grade > 10
        return (2.0 * grade).round(0) / 2.0
    end
end
