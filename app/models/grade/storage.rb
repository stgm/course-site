module Grade::Storage
    extend ActiveSupport::Concern

    def grade
        (g = super) && (g/10.0).round(1)
    end

    def calculated_grade
        (g = super) && (g/10.0).round(1)
    end

    def grade=(new_grade)
        if new_grade.blank? # erases the grade
            return super(nil)
        elsif new_grade.class == String
            new_grade.sub!(/,/,'.')
            case self.pset.grade_type
            when 'float', 'points'
                super(10.0 * new_grade.to_f)
            else # integer, pass
                super(10.0 * new_grade.to_i)
            end
        else
            case self.pset.grade_type
            when 'float', 'points'
                super(10.0 * new_grade.to_f)
            else # integer, pass
                super(10.0 * new_grade.to_i)
            end
        end
    end
end
