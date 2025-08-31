module User::Attendee

    extend ActiveSupport::Concern

    included do
        has_many :attendance_records
    end

    def log_attendance(is_local)
        # get current hour
        cutoff_time = Time.now.beginning_of_hour

        # save attendance record or update localness of request
        ar = AttendanceRecord.where(user_id: self.id, cutoff: cutoff_time).first_or_initialize
        ar.local = is_local
        ar.save

        # update user last_seen
        self.update_columns(last_seen_at: Time.now)
        self.take_attendance
    end

    def take_attendance
        symbols = "▁▂▃▄▅▆▇█"
        user_attendance = self.attendance_records.group_by_day(:cutoff, default_value: 0, range: 7.days.ago.beginning_of_day...Time.now).count.values
        graph = user_attendance.map { |v| symbols[[ v, 7 ].min] }.join("")
        self.update_attribute(:attendance, graph)
    end

    def attendance_graph
        if self.last_seen_at.blank?
            return "▁" * 8
        else
            last_seen_days_ago = (Date.current - self.last_seen_at.to_date).to_i
            return self.attendance.split("").drop(last_seen_days_ago).join + ("▁" * [ last_seen_days_ago, 8 ].min)
        end
    end

end
