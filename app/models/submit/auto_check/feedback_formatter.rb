module Submit::AutoCheck::FeedbackFormatter

    extend ActiveSupport::Concern

    def has_auto_feedback?
        self.check_results.present?
    end

    def formatted_auto_feedback
        return "" if self.check_results.blank?
        checks = self.check_results["checks"]

        # if there is no results object, an error must have occurred
        # during startup
        return self.check_results["error"]["value"] if checks.nil?

        # now generate basic feedback from each item
        checks.map do |item|
            format_check(item["description"], item["message"])
        end.join
    end

    def format_check(description, explanation)
        result = " #{description}\n"
        if explanation.present?
            # indent extra info, even if multi-line
            result << explanation.split("\n").map { |x| "      #{x}\n" }.join
        end
        result
    end

    def has_run_log?
        self.check_results&.dig("checks")&.any? { |x| x["log"].present? }
    end

    def formatted_run_log
        self.check_results["checks"].filter_map { |x| x["log"].presence }.
            join("\n\n-------------------\n\n")
    end

end
