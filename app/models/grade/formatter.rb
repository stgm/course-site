module Grade::Formatter
    extend ActiveSupport::Concern

    def format(weight=nil)
        current_grade = assigned_grade
        return '--' if current_grade.blank?
        case self.type || 'float'
        when 'points'
            if current_grade == -1 && weight.present?
                # display full points
                return weight.to_s
            elsif current_grade.to_i == current_grade
                # display integer grade
                return current_grade.to_i.to_s
            else
                # display decimal grade if decimals are available
                return current_grade.to_s
            end
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
