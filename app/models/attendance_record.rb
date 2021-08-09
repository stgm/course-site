class AttendanceRecord < ApplicationRecord
    def self.create_for_user(user, is_local)
        # get current hour
        real_time = Time.now
        cutoff_time = Time.new(real_time.year, real_time.month, real_time.mday, real_time.hour)

        # save attendance record or update localness of request
        ar = AttendanceRecord.where(user_id: user.id, cutoff: cutoff_time).first_or_initialize
        ar.local = is_local
        ar.save

        # update user last_seen
        user.update_columns(last_seen_at: Time.now)
    end
end
