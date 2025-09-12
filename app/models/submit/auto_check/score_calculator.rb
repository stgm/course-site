module Submit::AutoCheck::ScoreCalculator

    extend ActiveSupport::Concern

    def automatic_scores
        return {} if grading_config.nil? || grading_config["automatic"].nil?

        # take all automatic rules and use it to create hash of grades
        results = grading_config["automatic"].transform_values do |rule|
            begin
                # evaluate grade formula from config, giving access to
                # the current instance
                self.instance_eval(rule)
            rescue
                nil
            end
        end

        return results
    end

    # this method may be called in grading.yml grade formulas
    def correctness_score
        return nil unless self.check_results&.dig("summary").present?
        return 0 unless self.check_results["summary"]["total_check_count"] > 0
        self.check_results["summary"]["passed_check_count"].to_f /
            self.check_results["summary"]["total_check_count"]
    end

end
