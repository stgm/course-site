module User::Loginable
    extend ActiveSupport::Concern

    included do
        has_secure_token
        has_many :logins
    end

    def self.find_by_login(login)
        if login
            if login = Login.find_by_login(login)
                return login.user
            end
        end
    end

    def login_id
        return self.logins.first.try(:login) || self.token
    end
end
