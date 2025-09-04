module Submit::AutoCheck::FeedbackFormatter

    extend ActiveSupport::Concern

    def has_auto_feedback?
        self.check_results.present?
    end

    def formatted_auto_feedback
        return "" if self.check_results.blank?
        runs = self.check_results["runs"]

        # we might have older type check results in the db
        return "Legacy check results can't be displayed, please re-submit if needed." if self.check_results["checks"].present?

        # if there is no runs object, an error must have occurred
        # during startup
        return self.check_results if runs.nil?

        if runs.size == 1
            # present just the results of the checks of this single run
            format_run(runs[0]["checks"])
        else
            runs.map do |run|
                # include name of checked program/slug
                run["name"] + "\n" +
                format_run(run["checks"])
            end.join
        end
    end

    def format_run(checks)
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
