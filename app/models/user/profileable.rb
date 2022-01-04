module User::Profileable
    extend ActiveSupport::Concern

    included do
        serialize :progress, Hash
        enum status: [:active, :registered, :inactive, :done], _default: 'registered', _prefix: 'status'
        scope :watching, -> { where(alarm: true) }
    end

    def create_profile(params, login)
        # cancel this thing if registration is not open (but not if first user)
        raise unless User.none? || Schedule.none? || Schedule.default

        self.assign_attributes(params)
        # TODO ugly: default user has "empty" schedule, which we recognize here
        self.schedule = Schedule.default if self.schedule.blank?
        self.save!
        self.logins.create(login: login) unless self.logins.any?
    end

    def initials
        name.split.map(&:first).join
    end

    def suspect_name
        first, *rest = *name.split
        first + " " + rest.map(&:first).join()
    end

    def valid_profile?
        return self.persisted? && !self.name.blank?
    end
end
