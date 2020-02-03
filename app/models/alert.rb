class Alert < ApplicationRecord

	scope :having_schedule_or_nil, ->(schedule) { Alert.unscoped.where(schedule_id: [nil] << (schedule && schedule.id)).order("created_at desc") }

end
