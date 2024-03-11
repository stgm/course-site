module Grade::Storage
    extend ActiveSupport::Concern

    def grade
        (g = super) && (g/10.0)
    end

    def calculated_grade
        (g = super) && (g/10.0)
    end

    def grade=(new_grade)
        if new_grade.blank? # erases the grade
            super(nil)
        elsif new_grade.class == String
            new_grade.sub!(/,/,'.')
            case self.type
            when 'float', 'points'
                super(10.0 * new_grade.to_f)
            else # integer, pass
                super(10.0 * new_grade.to_i)
            end
        else
            case self.type
            when 'float', 'points'
                super(10.0 * new_grade.to_f)
            when 'integer', 'pass'
                super(10.0 * new_grade.to_i)
            else
                super(10.0 * new_grade.to_f)
            end
        end
    end

    def calculated_grade=(new_grade)
        if new_grade.blank?
            super(nil)
        else
            super((new_grade * 10.0).round)
        end
    end
end
