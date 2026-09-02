class GradingConfig

    def self.base
        GradingConfig.new
    end

    def self.with_schedule(schedule)
        if String === schedule
            GradingConfig.new(schedule)
        else
            GradingConfig.new(schedule&.name)
        end
    end

    def self.each_schedule(&block)
        Settings.schedule_grading.keys.each(&block)
    end

    # Component strategies of User::FinalGradeCalculator. An absent type means
    # "average", which is why it is in here as well.
    COMPONENT_TYPES = [ nil, "average", "maximum", "points", "points_last",
                        "pass_all", "pass_any", "pass_first", "pass_last" ].freeze

    # Components that report a pass (-1) instead of a grade on a 1--10 scheme,
    # and so only make sense inside a pass/fail final grade
    PASS_COMPONENT_TYPES = [ "pass_all", "pass_any", "pass_first", "pass_last" ].freeze

    def initialize(schedule_name = nil)
        # takes content from the base grading.yml
        # and overwrites with content from the schedule grading.yml
        @config = merge_configs Settings.grading || {},
                                Settings.schedule_grading[schedule_name] || {}
        @config = normalize_lists @config
        @schedule_name = schedule_name || "Base"
    end

    def grades
        @config["grades"] || {}
    end

    # final grade name => { "type" => "float"|"pass", "components" => { name => weight } }
    def calculation
        @config["calculation"] || {}
    end

    def modules
        @config["modules"] || {}
    end

    def exams
        grades.select { |name, config| config["exam"] == true }.map { |name, _| name }
    end

    def tests
        grades.select { |name, config|
            config["is_test"] == true || config["exam"]
        }.map { |name, _| name }
    end

    def components
        @config.select { |k, v| v["submits"] }
    end

    # Components holding exam material. A final grade waits for one of them to be
    # attempted before it is registered: see User::FinalGradeCalculator#attempted?
    def exam_components
        components.select { |name, config| config["exam"] == true }.keys
    end

    # submits that must be passed before the given pset may be submitted
    def required_submits_for(pset_name)
        components.
            select { |k, v| v["submits"].keys.any? { |name| test_of(name) == pset_name } }.
            flat_map { |k, v| v["requirement"] || [] }.
            uniq
    end

    def self.load(new_settings, schedule_name = nil)
        if schedule_name.blank?
            Settings.grading = new_settings
        else
            Settings.schedule_grading = Settings.schedule_grading.merge({ schedule_name => new_settings })
        end
    end

    def final_grade_names
        calculation.keys
    end

    # Report all final grades defined in the course, from
    # all schedules together
    def self.all_final_grade_names
        configs = [ base ] + Settings.schedule_grading.keys.map { |name| with_schedule(name) }
        configs.flat_map(&:final_grade_names).uniq.sort
    end

    def categories
        calculation.map { |final_grade, spec| spec["components"].keys }.flatten.sort.uniq
    end

    def categories_with_psets
        categories.map { |cat| [ cat, @config[cat]["submits"].keys ] }
    end

    def categories_for_progress
        @config.select { |category, value| value && (value["show_progress"] || value["show_overview"]) }
    end

    def validate
        @errors = []
        progress_categories = categories_for_progress
        if progress_categories.any?
            if @config["grades"].blank?
                @errors << "Problem loading grading.yml for #{@schedule_name}. There are grading categories like #{progress_categories.first.first} but no grades section is present specifying how to calculate grades."
                return @errors
            end
            all_submit_names = progress_categories.filter_map do |k, v|
                submits = v["submits"]
                [ k, submits.keys ] if submits
            end
            invalid_grade_names = all_submit_names.map { |k, v| [ k, v.select { |name| !@config["grades"].include?(test_of(name)) } ] }.select { |k, v| v.any? }.map { |k, v| "#{k}/#{v.join(',')}" }
            if invalid_grade_names.any?
                @errors << "Problem loading grading.yml for #{@schedule_name}. Grades #{invalid_grade_names.join('; ')} are defined, but matching names could not be found in the grades section."
            end
        end

        grade_components = self.calculation.values.map { |spec| spec["components"].keys }.flatten
        missing_components = grade_components.select { |name| !name.in? self.components.keys }
        if missing_components.size > 0
            @errors << "Problem loading grading.yml for #{@schedule_name}. Final grade component definitions are used but undefined: #{missing_components.join('; ')}."
        end

        unknown_types = self.components.reject { |name, component| component["type"].in? COMPONENT_TYPES }
        if unknown_types.any?
            @errors << "Problem loading grading.yml for #{@schedule_name}. Components #{unknown_types.map { |name, c| "#{name}/#{c['type']}" }.join('; ')} have an unknown type. Choose from: #{COMPONENT_TYPES.compact.join(', ')}."
        end

        if @config["grades"].present?
            invalid_requirement_names = self.components.
                filter_map { |k, v| [ k, v["requirement"].reject { |name| @config["grades"].include?(name) } ] if v["requirement"] }.
                select { |k, v| v.any? }.
                map { |k, v| "#{k}/#{v.join(',')}" }
            if invalid_requirement_names.any?
                @errors << "Problem loading grading.yml for #{@schedule_name}. Requirements #{invalid_requirement_names.join('; ')} are defined, but matching names could not be found in the grades section."
            end
        end

        # a component may name a part of a test as "test.part", and that part has to be
        # declared as a subgrade of it: a typo would otherwise read as "not attempted"
        if @config["grades"].present?
            unknown_parts = self.components.filter_map do |name, component|
                parts = (component["submits"] || {}).keys.select { |s| s.include?(".") }.reject do |s|
                    test, part = s.split(".", 2)
                    @config["grades"][test].to_h["subgrades"].to_h.key?(part)
                end
                "#{name}/#{parts.join(',')}" if parts.any?
            end
            if unknown_parts.any?
                @errors << "Problem loading grading.yml for #{@schedule_name}. Subgrades #{unknown_parts.join('; ')} are used, but matching subgrades could not be found in the grades section."
            end
        end

        # a pass component reports -1, which is meaningless inside a weighted average,
        # unless its weight is 0: then only a fail or missing grade can affect the result
        self.calculation.each do |final_name, spec|
            next if spec["type"] == "pass"
            pass_components = spec["components"].select { |name, weight| weight != 0 && self.components[name].to_h["type"].in?(PASS_COMPONENT_TYPES) }.keys
            if pass_components.any?
                @errors << "Problem loading grading.yml for #{@schedule_name}. Final grade #{final_name} is not of type pass, but uses pass/fail components: #{pass_components.join('; ')}."
            end
        end

        # weights say nothing about a pass, so those components are written as a list
        map_components = self.calculation.select { |final_name, spec| spec["type"] == "pass" && !spec["listed"] }
        if map_components.any?
            @errors << "Problem loading grading.yml for #{@schedule_name}. Final grades #{map_components.keys.join('; ')} are of type pass, so their components should be written as a list of names, without weights."
        end

        return @errors
    end

    # for the admin grading overview
    def overview
        psets = Pset.order(:order).index_by &:name

        # include final grade components that were marked as "show progress"
        # (submits naming a pset that no longer exists are skipped, rather
        # than crashing the overview)
        r = @config.
            select { |c, v| v["show_progress"] || v["show_overview"] }.
            map { |c, v| [ c, should_summarize(v), tests_with_weights(v["submits"]).filter_map { |name, weight| [ psets[name], weight ] if psets[name] } ] }

        # include all final grades at the end
        r = r + [ [ "Final", nil, final_grade_names.filter_map { |k| psets[k] } ] ] if final_grade_names.any?

        # if nothing's there, include all assignments
        r = [ [ "Assignments", nil, Pset.order(:order) ] ] if r.blank?

        return r
    end

    def should_summarize(component_config)
        return component_config["small_block_overview"].present? ? :blocks : nil
    end

    def overview_config
        # determine the overall categories to show
        overview = @config.select { |category, value| value["show_progress"] }

        # the result is built up fresh rather than written back into the config, which
        # a second call would otherwise read as its input
        overview.to_h do |category, content|
            # a component that names parts of a test shows only those parts, not every
            # subgrade the test happens to have
            named_parts = (content["submits"] || {}).keys.filter_map { |name| name.split(".", 2)[1] }

            # remove psets having weight 0 or bonus, only select pset names
            submits = tests_with_weights((content["submits"] || {})
                .reject { |submit, weight| (weight == 0 || weight == "bonus") })

            # determine subgrades if any
            subgrades = []
            show_calculated = false
            submits.each do |submit, weight|
                if grades[submit].present?
                    if may_show_subgrades?(submit)
                        subgrades += self.grades[submit]["subgrades"].keys
                    end
                    show_calculated = true if !self.grades[submit]["hide_calculated"]
                end
            end
            subgrades = subgrades & named_parts if named_parts.any?

            [ category, content.merge(
                "submits" => submits,
                "subgrades" => subgrades.uniq,
                "show_calculated" => show_calculated) ]
        end
    end

    # The test a component's submit belongs to: a plain name is the test itself, and
    # "test.part" names one of its subgrades.
    def test_of(name)
        name.split(".", 2).first
    end

    # For display the parts of one test collapse back into the test itself, with their
    # weights added up, so that a component listing several parts shows one row per test.
    def tests_with_weights(submits)
        (submits || {}).each_with_object({}) do |(name, weight), result|
            test = test_of(name)
            result[test] =
                if result[test].is_a?(Numeric) && weight.is_a?(Numeric)
                    result[test] + weight
                elsif result.key?(test)
                    result[test]
                else
                    weight
                end
        end
    end

    def may_show_subgrades?(submit)
        !grades[submit]["hide_subgrades"] &&
        grades[submit]["subgrades"].present?
    end

    def settings
        @config["_settings"]
    end

    private

    # The assignments of a component, its bonus assignments and the components of a
    # final grade may each be written as a plain list of names, for when there is
    # nothing to weigh. Everything downstream reads all three as name => weight maps,
    # so the lists are converted here, once, right after merging.
    #
    def normalize_lists(config)
        config.to_h do |key, section|
            next [ key, section ] unless section.is_a?(Hash)

            if key == "calculation"
                [ key, section.transform_values { |spec| normalize_final_grade(spec) } ]
            else
                [ key, normalize_requirement(listed_as_weights(section, "submits", "bonus")) ]
            end
        end
    end

    # A component's "requirement" may be written as a single submit name or
    # a list of names; everything downstream reads it as a list.
    #
    def normalize_requirement(section)
        return section unless section.key?("requirement")

        section.merge("requirement" => Array(section["requirement"]))
    end

    # A final grade is { "type" => ..., "components" => { name => weight } }. Without a
    # components key the whole map is the components, which is how numeric final grades
    # have always been written.
    #
    def normalize_final_grade(spec)
        return spec unless spec.is_a?(Hash)

        spec = { "components" => spec.except("type") }.merge(spec.slice("type")) if !spec.key?("components")
        normalized = listed_as_weights(spec, "components").
            merge("type" => spec["type"] || "float", "listed" => spec["components"].is_a?(Array))
        optional_marked(normalized)
    end

    # A component whose name carries a "?" is optional in that final grade: it is left out
    # when the student made nothing in it. The mark is stripped here and collected under
    # "optional", so nothing downstream has to know how it was written.
    #
    def optional_marked(spec)
        optional = spec["components"].keys.select { |name| name.end_with?("?") }
        return spec if optional.empty?

        spec.merge(
            "components" => spec["components"].transform_keys { |name| name.delete_suffix("?") },
            "optional" => optional.map { |name| name.delete_suffix("?") })
    end

    def listed_as_weights(section, *keys)
        keys.inject(section) do |result, key|
            result[key].is_a?(Array) ? result.merge(key => result[key].index_with(1)) : result
        end
    end

    def merge_configs(grades1, grades2)
        result = grades1.except(:templates)

        grades2.except(:templates).each do |key, value|
            if key == "grades"
                result["grades"] ||= {}
                value.each do |grade, props|
                    result["grades"][grade] ||= {}
                    result["grades"][grade].merge!(props) if props.is_a?(Hash)
                end
            elsif value.is_a?(Hash) && result[key].is_a?(Hash)
                result[key] = result[key].merge(value)
            else
                result[key] = value
            end
        end

        result
    end

end
