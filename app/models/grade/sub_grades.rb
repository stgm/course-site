module Grade::SubGrades
    extend ActiveSupport::Concern

    included do
        # creates OpenStruct from serialized data to ensure method access in grading formulas
        serialize :subgrades, SubGrades

        after_initialize do
            # this adds automatic grades to the subgrades quite aggressively
            if !self.persisted? && self.submit.present?
                # add any newly found autogrades to the subgrades as default
                self.submit.automatic_scores.each do |k,v|
                    self.subgrades[k] = v if not self.subgrades[k].present?
                end
            end
        end
    end

    def subgrades=(val)
        # take this opportunity to convert any stringified stuff to numbers
        val.each do |k,v|
            # get type from grading config
            begin
                grade_type = grading_config['subgrades'][k]
            rescue
                grade_type = "integer"
            end

            case grade_type
            when "integer", "pass", "boolean"
                val[k] = v.to_i unless v == ""
            when "float"
                val[k] = v.sub(",", ".").to_f unless v == ""
            end
        end if val

        super OpenStruct.new val.to_h if val
    end

    class SubGrades
        def self.dump(value)
            # assumes OpenStruct
            value.to_h.to_yaml
        end

        def self.load(value)
            if value.present?
                OpenStruct.new YAML.safe_load(value, permitted_classes: [Symbol, OpenStruct])
            else
                OpenStruct.new
            end
        end
    end
end
