module User::Profileable
    extend ActiveSupport::Concern

    included do
        serialize :progress, Hash
        enum status: [:active, :registered, :inactive, :done], _default: 'registered', _prefix: 'status'
        scope :watching, -> { where(alarm: true) }
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
