module User::Profileable
    extend ActiveSupport::Concern

    included do
        serialize :progress, coder: YAML, type: Hash
        enum :status, { active: 0, registered: 1, inactive: 2, done: 3 }, default: :registered, prefix: :status
        scope :watching, -> { where(alarm: true) }
    end

    def name_with_pronouns
        if pronouns
            "#{name} (#{self.pronouns})"
        else
            name
        end
    end

    def first_name_with_pronouns
        if pronouns
            "#{name.split[0]} (#{self.pronouns})"
        else
            name.split[0]
        end
    end

    def designation
        if Schedule.many?
            group_name || schedule_name
        end
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
