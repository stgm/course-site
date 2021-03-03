module Grading

    def self.settings
        Settings.grading || {}
    end

    def self.grades
        settings['grades'] || {}
    end

    def self.calculation
        settings['calculation'] || {}
    end

    def self.load(new_settings)
        Settings.grading = new_settings
    end

    def self.final_grade_names
        settings['calculation'].keys
    end

    def self.validate
        grading_config = settings
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

end
