module User::Attendee
    extend ActiveSupport::Concern

    included do
        has_many :attendance_records
    end

    def take_attendance
        symbols = "▁▂▃▄▅▆▇█"
        user_attendance = self.attendance_records.group_by_day(:cutoff, default_value: 0, range: 7.days.ago...Time.now).count.values
        graph = user_attendance.map { |v| symbols[[v,7].min] }.join("")
        self.update_attribute(:attendance, graph)
    end
end
