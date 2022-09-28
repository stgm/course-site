class AttendanceRecord < ApplicationRecord
    def self.create_for_user(user, is_local)
        # get current hour
        cutoff_time = Time.now.beginning_of_hour

        # save attendance record or update localness of request
        ar = AttendanceRecord.where(user_id: user.id, cutoff: cutoff_time).first_or_initialize
        ar.local = is_local
        ar.save

        # update user last_seen
        user.update_columns(last_seen_at: Time.now)
        user.take_attendance
    end
end
