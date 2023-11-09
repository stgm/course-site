module Grade::Formatter
    extend ActiveSupport::Concern

    def format
        current_grade = assigned_grade
        return '--' if current_grade.blank?
        case self.type || 'float'
        when 'points'
            return current_grade.to_i.to_s
        when 'integer'
            return current_grade.to_i.to_s
        when 'pass'
            if current_grade.between?(-1,0)
                return (current_grade==-1 && 'v' || 'x')
            else
                return current_grade.to_s
            end
        else # float
            return current_grade.to_s
        end
    end
end
