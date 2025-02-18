class Alert < ApplicationRecord

    belongs_to :schedule, optional: true
    delegate :name, to: :schedule, prefix: true

    scope :having_schedule_or_nil, ->(schedule) do
        Alert.
            unscoped.
            where(schedule_id: [ nil ] << (schedule && schedule.id)).
            order("created_at desc")
    end

end
