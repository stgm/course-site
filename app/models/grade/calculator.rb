module Grade::Calculator

    extend ActiveSupport::Concern

    included do
        before_save :set_calculated_grade
    end

    def set_calculated_grade
        # This always runs, even if no subgrades have been changed. This is to
        # ensure that grades are also recalculated after the grade *formula* has
        # changed.
        calculated_grade = calculate_grade
        if calculated_grade.present?
            case self.type
            when "float", "points"
                # calculated_grade = calculated_grade
            else # integer, pass
                calculated_grade = calculated_grade.round
            end
            self.calculated_grade = calculated_grade
        else
            self.calculated_grade = nil
        end
    end

    def calculate_grade
        GradingFormulaEvaluator.evaluate(calculation, formula_variables,
                                         aggregate_keys: declared_subgrades)
    rescue
        nil
    end

    # The value of the sum_all or count_all in the formula, for interfaces that
    # want to show the running total next to the grade. Nil when the formula
    # uses neither.
    def aggregate_value
        function = GradingFormulaEvaluator.aggregate_function(calculation)
        return nil unless function
        GradingFormulaEvaluator.evaluate(function.to_s, formula_variables,
                                         aggregate_keys: declared_subgrades)
    rescue
        nil
    end

    private

    def calculation
        grading_config["calculation"]
    end

    def declared_subgrades
        (grading_config["subgrades"] || {}).keys
    end

    # Subgrades that are declared but not filled in are passed as explicit nils,
    # so that sum_all can tell "not filled in" from "not part of this test".
    def formula_variables
        declared_subgrades.index_with { nil }.merge(subgrades.to_h)
    end

end
