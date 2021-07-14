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

    def self.load(new_settings)
        Settings.grading = new_settings
    end

    def self.final_grade_names
        all['calculation'].keys
    end

    def self.validate
        grading_config = self.all
        progress_categories = grading_config.select { |category, value| value['show_progress'] }
        if progress_categories.any?
            if grading_config['grades'].blank?
                @errors << "Problem loading grading.yml. There are grading categories like #{progress_categories.first.first} but no grades section is present specifying how to calculate grades."
                return
            end
            all_submit_names = progress_categories.map { |k,v| [k,v['submits'].keys] }
            invalid_grade_names = all_submit_names.map { |k,v| [k,v.select { |name| !grading_config['grades'].include?(name) }] }.select { |k,v| v.any? }.map{|k,v| "#{k}->#{v.join(',')}"}
            if invalid_grade_names.any?
                @errors << "Problem loading grading.yml. Some grades were specified as part of the final grade, but could not be found in the grades section: #{invalid_grade_names.join('; ')}."
                return
            end
        end
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
