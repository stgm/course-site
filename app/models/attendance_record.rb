class AttendanceRecord < ApplicationRecord

    def self.reset_stale_locations
        return if Settings.reset_stale_locations > 30.minutes.ago
        Settings.reset_stale_locations = Time.current

        current_hour = Time.current.beginning_of_hour
        previous_hour = current_hour - 1.hour

        users_with_recent_records = AttendanceRecord
          .where(cutoff: [ previous_hour, current_hour ])
          .where(confirmed: true)
          .select(:user_id)

        User
          .where.not(id: users_with_recent_records)
          .where.not([last_known_location: nil, location_confirmed: false])
          .update_all(last_known_location: nil, location_confirmed: false)
    end

end
