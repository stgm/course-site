module Grade::Formatter

    extend ActiveSupport::Concern

    def format(weight = nil)
        Grade::Formatter.format_value(assigned_grade, self.type, weight)
    end

    # Formatting a bare number, for callers that have a grade value but no Grade
    # record to ask — or that want the calculated grade specifically, where
    # #format would report a manually assigned one instead.
    def self.format_value(grade, type, weight = nil)
        return "--" if grade.blank?
        case type || "float"
        when "points"
            if grade == -1 && weight.present?
                # display full points
                return weight.to_s
            elsif grade.to_i == grade
                # display integer grade
                return grade.to_i.to_s
            else
                # display decimal grade if decimals are available
                return grade.to_s
            end
        when "integer"
            return grade.to_i.to_s
        when "pass"
            if grade.between?(-1, 0)
                return (grade==-1 && "v" || "x")
            else
                return grade.to_s
            end
        else # float
            return grade.to_s
        end
    end

end
