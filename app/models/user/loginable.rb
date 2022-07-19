module User::Loginable
    extend ActiveSupport::Concern

    included do
        has_secure_token
        has_many :logins
    end

    def self.authenticate(login)
        find_by_login(login)
    end

    def login_id
        return self.logins.first.try(:login) || self.token
    end
end
