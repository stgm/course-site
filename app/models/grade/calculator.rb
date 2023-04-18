module Grade::Calculator
    extend ActiveSupport::Concern

    included do
        before_save :set_calculated_grade
    end

    def set_calculated_grade
        # This always runs, even if no subgrades have been changed. This is to ensure that grades are also recalculated after the grade formula has changed.
        calculated_grade = calculate_grade
        if calculated_grade.present?
            case self.pset.grade_type
            when 'float', 'points'
                # calculated_grade = calculated_grade
            else # integer, pass
                calculated_grade = calculated_grade.round
            end
            self.calculated_grade = calculated_grade * 10
        else
            self.calculated_grade = nil
        end
    end

    def calculate_grade
        calculations = GradingConfig.grades
        return nil if calculations.nil?

        pset_name = self.pset.name
        return nil if calculations[pset_name].nil? or calculations[pset_name]['calculation'].nil?

        begin
            cg = self.subgrades.instance_eval(calculations[pset_name]['calculation'])
        rescue
            cg = nil
        end

        return cg
    end
end
