module User::Authenticatable

    extend ActiveSupport::Concern

    included do
        def self.authenticate(user_data)
            if user = User.find_by_mail(user_data[:mail])
                return authenticate_existing(user)
            else
                return authenticate_new(user_data)
            end
        end

        # finds existing users to login, but also checks whether login is allowed at this time
        def self.authenticate_existing(user)
            case Settings.registration_phase
            when 'before'
                return user.staff? && user
            when 'during', 'after'
                return user
            when 'archival'
                return user.admin? && user
            end
        end

        # creates a new user, but only if allowed at this time
        def self.authenticate_new(user_data)
            case Settings.registration_phase
            when 'before'
                if User.none?
                    User.create!(user_data.merge(role: 'admin'))
                else
                    return false
                end
            when 'before', 'after', 'archival'
                return false
            when 'during'
                # if course is open, we also need a schedule to be open
                if Schedule.default
                    return User.create!(user_data)
                else
                    return false
                end
            end
        end
    end

end
