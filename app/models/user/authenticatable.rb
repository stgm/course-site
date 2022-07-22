module User::Authenticatable

    extend ActiveSupport::Concern

    included do
        def self.authenticate(user_data)
            if user = User.find_by_mail(user_data[:mail])
                logger.info "FOUND BY MQIL"
                logger.info user.inspect
                x= authenticate_existing(user)
                logger.info x.inspect
                return x
            else
                return authenticate_new(user_data)
            end
        end

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

        def self.authenticate_new(user_data)
            case Settings.registration_phase
            when 'before', 'after', 'archival'
                return false
            when 'during'
                x=  User.create!(user_data)
                logger.info x.inspect
                return x
            end
        end
    end

end
