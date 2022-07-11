module User::Loginable
    extend ActiveSupport::Concern

    included do
        has_secure_token
        has_many :logins
    end

    # def self.find_by_login(login)
    # 	puts "HAH"
    # 	if user = super(login)
    # 		puts "HUH"
    # 		return user
    # 	elsif login = Login.find_by_login(login)
    # 		puts "HUH2"
    #
    # 		return login.user
    # 	end
    # end

    def self.authenticate(login)
        find_by_login(login)
    end

    def login_id
        return self.logins.first.try(:login) || self.token
    end
end
