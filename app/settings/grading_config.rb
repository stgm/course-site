module GradingConfig

    def self.all
        Settings.grading || {}
    end

    def self.grades
        all['grades'] || {}
    end

    def self.calculation
        all['calculation'] || {}
    end

    def self.modules
        all['modules'] || {}
    end

    def self.tests
        all['tests'] || {}
    end

    def self.load(new_settings)
        Settings.grading = new_settings
    end

    def self.final_grade_names
        self.calculation.keys
    end

    def self.categories
        calculation.map{|final_grade,cat| cat.keys}.flatten.sort.uniq
    end

    def self.categories_with_psets
        categories.map{|cat| [cat, all[cat]['submits'].keys]}
    end

    def self.overview
        psets = Pset.order(:order).index_by &:name
        # include final grade components that were marked as "show progress"
        r = all.select { |c,v| v['show_progress'] }.
            map { |c,v| [c, v['submits'].map {|k,v| psets[k]}] }
        # include modules (this is redundant legacy)
        # r = modules.
        #     map { |c,v| [c, v.map {|k,v| psets[k]}] } + r if GradingConfig.modules
        # include all final grades at the end
        r = r + [["Final", final_grade_names.map {|k,v| psets[k]}]] if final_grade_names.any?
        # if nothing's there, include all assignments
        r = [["Assignments", Pset.order(:order)]] if r.blank?
        return r
    end

    def self.validate
        @errors = []
        grading_config = self.all
        progress_categories = grading_config.select { |category, value| value['show_progress'] }
        if progress_categories.any?
            if grading_config['grades'].blank?
                @errors << "Problem loading grading.yml. There are grading categories like #{progress_categories.first.first} but no grades section is present specifying how to calculate grades."
                return @errors
            end
            all_submit_names = progress_categories.map { |k,v| [k,v['submits'].keys] }
            invalid_grade_names = all_submit_names.map { |k,v| [k,v.select { |name| !grading_config['grades'].include?(name) }] }.select { |k,v| v.any? }.map{|k,v| "#{k}->#{v.join(',')}"}
            if invalid_grade_names.any?
                @errors << "Problem loading grading.yml. Some grades were specified as part of the final grade, but could not be found in the grades section: #{invalid_grade_names.join('; ')}."
                return @errors
            end
        end
        return @errors
    end

    def self.overview_config
        return {} if not self.all

        # determine the categories to show
        overview = self.all.select { |category, value| value['show_progress'] }

        overview.each do |category, content|
            # remove weight 0 and bonus, only select pset names
            content['submits'] = content['submits']
                .reject { |submit, weight| (weight == 0 || weight == 'bonus') }
                .keys

            # determine subgrades
            subgrades = []
            show_calculated = false
            content['submits'].each do |submit, weight|
                if !self.grades[submit]['hide_subgrades']
                    subgrades += self.grades[submit]['subgrades'].keys
                end
                show_calculated = true if !self.grades[submit]['hide_calculated']
            end
            content['subgrades'] = subgrades.uniq
            content['show_calculated'] = show_calculated
        end

        return overview
    end

end
