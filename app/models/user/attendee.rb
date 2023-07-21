module User::Attendee
    extend ActiveSupport::Concern

    included do
        has_many :attendance_records
        scope :long_time_not_seen, -> { where('last_seen_at < ?', 1.week.ago) }

        def self.set_inactives_to_inactive!
            User.status_active.long_time_not_seen.update(status: :inactive)
        end
    end

    def take_attendance
        symbols = "▁▂▃▄▅▆▇█"
        user_attendance = self.attendance_records.group_by_day(:cutoff, default_value: 0, range: 7.days.ago.beginning_of_day...Time.now).count.values
        graph = user_attendance.map { |v| symbols[[v,7].min] }.join("")
        self.update_attribute(:attendance, graph)
    end

    def attendance_graph
        if self.last_seen_at.blank?
            return "▁" * 8
        else
            last_seen_days_ago = (Date.current - self.last_seen_at.to_date).to_i
            return self.attendance.split('').drop(last_seen_days_ago).join + ('▁' * [last_seen_days_ago,8].min)
        end
    end

    def long_time_not_seen?
        last_seen_at < 1.week.ago
    end
end
