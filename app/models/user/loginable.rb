module User::Loginable

    extend ActiveSupport::Concern

    included do
        has_secure_token
        has_many :logins
    end

    def defacto_student_identifier
        # require student-number to be available, or fall back to old logins
        return self.student_number || self.logins.first.try(:login)
    end

end
