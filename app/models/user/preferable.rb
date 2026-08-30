# Settings the user chose for themselves, kept in one serialized column.
module User::Preferable

    extend ActiveSupport::Concern

    included do
        serialize :preferences, coder: YAML, type: Hash, default: {}
    end

    # Modules the user has collapsed in the overview, per schedule slug.
    def collapsed_modules(schedule)
        preferences.fetch("collapsed_modules", {})[schedule.slug] || []
    end

    # Returns false when the record could not be saved, so the caller does not
    # report a preference as stored when it was not.
    def collapse_modules(schedule, names)
        preferences["collapsed_modules"] ||= {}
        preferences["collapsed_modules"][schedule.slug] = Array(names).map(&:to_s)
        save
    end

end
