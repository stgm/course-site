module Grade::SubGrades
    extend ActiveSupport::Concern

    included do
        # this is an OpenStruct to make sure that subgrades can be referenced as a method
        # for use in the grade calculation formulae in grading.yml
        serialize :subgrades, OpenStruct

        after_initialize do
            # this adds automatic grades to the subgrades quite aggressively
            if !self.persisted?
                # add any newly found autogrades to the subgrades as default
                self.submit.automatic_scores.each do |k,v|
                    self.subgrades[k] = v if not self.subgrades[k].present?
                end
            end
        end
    end

    def subgrades=(val)
        # we would like this to be stored as an OpenStruct
        #return super if val.is_a? OpenStruct

        # take this opportunity to convert any stringified stuff to numbers
        val.each do |k,v|
            # get type from grading config
            begin
                grade_type = config['subgrades'][k]
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
end
