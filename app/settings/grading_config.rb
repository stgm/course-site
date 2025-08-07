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

    def initialize(schedule_name = nil)
        @config = merge_configs Settings.grading || {},
                                Settings.schedule_grading[schedule_name] || {}
        @schedule_name = schedule_name || "Base"
    end

    def grades
        @config["grades"] || {}
    end

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

    def categories
        calculation.map { |final_grade, cat| cat.keys }.flatten.sort.uniq
    end

    def categories_with_psets
        categories.map { |cat| [ cat, @config[cat]["submits"].keys ] }
    end

    def validate
        @errors = []
        progress_categories = @config.select { |category, value| value["show_progress"] }
        if progress_categories.any?
            if @config["grades"].blank?
                @errors << "Problem loading grading.yml for #{@schedule_name}. There are grading categories like #{progress_categories.first.first} but no grades section is present specifying how to calculate grades."
                return @errors
            end
            all_submit_names = progress_categories.map { |k, v| [ k, v["submits"].keys ] }
            invalid_grade_names = all_submit_names.map { |k, v| [ k, v.select { |name| !@config["grades"].include?(name) } ] }.select { |k, v| v.any? }.map { |k, v| "#{k}/#{v.join(',')}" }
            if invalid_grade_names.any?
                @errors << "Problem loading grading.yml for #{@schedule_name}. Grades #{invalid_grade_names.join('; ')} are defined, but matching names could not be found in the grades section."
            end
        end

        grade_components = self.calculation.values.map(&:keys).flatten
        missing_components = grade_components.select { |name| !name.in? self.components.keys }
        if missing_components.size > 0
            @errors << "Problem loading grading.yml for #{@schedule_name}. Final grade component definitions are used but undefined: #{missing_components.join('; ')}."
        end

        return @errors
    end

    # for the admin grading overview
    def overview
        psets = Pset.order(:order).index_by &:name

        # include final grade components that were marked as "show progress"
        r = @config.
            select { |c, v| v["show_progress"] || v["show_overview"] }.
            map { |c, v| [ c, should_summarize(v), v["submits"].map { |name, weight| [ psets[name], weight ] } ] }

        # include all final grades at the end
        r = r + [ [ "Final", nil, final_grade_names.map { |k, v| psets[k] } ] ] if final_grade_names.any?

        # if nothing's there, include all assignments
        r = [ [ "Assignments", nil, Pset.order(:order) ] ] if r.blank?

        return r
    end

    def should_summarize(component_config)
        return component_config["small_block_overview"].present? ? :blocks : nil
    end

    def overview_config
        # determine the categories to show
        overview = @config.select { |category, value| value["show_progress"] }

        overview.each do |category, content|
            # remove weight 0 and bonus, only select pset names
            content["submits"] = content["submits"]
                .reject { |submit, weight| (weight == 0 || weight == "bonus") }

            # determine subgrades
            subgrades = []
            show_calculated = false
            content["submits"].each do |submit, weight|
                if !self.grades[submit]["hide_subgrades"] && self.grades[submit]["subgrades"].present?
                    subgrades += self.grades[submit]["subgrades"].keys
                end
                show_calculated = true if !self.grades[submit]["hide_calculated"]
            end
            content["subgrades"] = subgrades.uniq
            content["show_calculated"] = show_calculated
        end

        return overview
    end

    private

    def merge_configs(grades1, grades2)
        first_without_grades = grades1.except(:templates, :grades)
        second_without_grades = grades2.except(:templates, :grades)

        merged_grades = (grades1["grades"] || {}).merge(grades2["grades"] || {})
        merged_rest = first_without_grades.merge(second_without_grades)
        merged_rest["grades"] = merged_grades

        return merged_rest
    end

end
