module User::Attendee

    extend ActiveSupport::Concern

    included do
        has_many :attendance_records
    end

    # 1) Log the current hit with an IP address
    #    - Context:
    #    - (c1) student could be new today -> new record, no inference of attendance
    #    - (c2) or logging another hour -> inference of attendance
    #    - (c3) or already confirmed by staff -> augment record with ip
    #
    # Tasks:
    #    - Upsert the current-hour record and sets ip
    #    - if (c2) and the ip matches, also confirm this record
    def log_attendance(ip:)
        now = Time.current
        cutoff = now.beginning_of_hour

        ApplicationRecord.transaction do
            ar = attendance_records.where(cutoff: cutoff).first_or_initialize
            prev = attendance_records.find_by(cutoff: ar.cutoff - 1.hour)

            # update current hour log
            ar.ip = ip
            # a confirmation carries forward from the same machine, but only
            # ever upwards: an unconfirmed previous hour must not undo a
            # check-in that staff just made for this one
            ar.confirmed = true if same_ip_as_previous_hour(ar, prev) && prev.confirmed
            ar.save!

            # update user properties
            update_columns(last_seen_at: now, attendance_confirmed: ar.confirmed)
            take_attendance
        end
    end

    # 2) Confirm attendance (set confirmed: true for the current hour).
    # Called when staff checks a student in on the attendance page.
    #
    # The record is created if the student has not loaded the site this hour:
    # a staff member seeing them in the room is itself the attendance datum,
    # and their ip fills in later if they do load a page.
    def confirm_attendance!(confirmed=true)
        now = Time.current
        cutoff = now.beginning_of_hour

        ApplicationRecord.transaction do
            # update current hour log
            ar = attendance_records.where(cutoff: cutoff).first_or_initialize
            ar.confirmed = confirmed
            ar.save!

            # update user
            update_columns(last_seen_at: now, attendance_confirmed: confirmed)
            take_attendance
        end
    end

    def take_attendance
        symbols = "▁▂▃▄▅▆▇█"
        user_attendance = attendance_records
          .group_by_day(:cutoff, default_value: 0, range: 7.days.ago.beginning_of_day...Time.current)
          .count
          .values
        graph = user_attendance.map { |v| symbols[[ v, 7 ].min] }.join("")
        update_attribute(:attendance, graph)
    end

    def attendance_graph
        if last_seen_at.blank?
            "▁" * 8
        else
            last_seen_days_ago = (Date.current - last_seen_at.to_date).to_i
            attendance.split("").drop(last_seen_days_ago).join + ("▁" * [ last_seen_days_ago, 8 ].min)
        end
    end

    private

    def same_ip_as_previous_hour(record, prev)
        prev&.ip.present?       && prev.ip       == record.ip
    end

end
