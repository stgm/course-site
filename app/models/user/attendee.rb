module User::Attendee

    extend ActiveSupport::Concern

    included do
        has_many :attendance_records
    end

    # 1) Log the current hit with just an IP.
    #    - Upserts the current-hour record and sets ip.
    #    - If previous hour was confirmed and both ip+location match, also confirm this record.
    def log_attendance(ip:)
        now = Time.current
        cutoff = now.beginning_of_hour

        ApplicationRecord.transaction do
            ar = attendance_records.where(cutoff: cutoff).first_or_initialize
            ar.ip = ip if ip

            infer_confirmation_from_previous!(ar, cutoff) unless ar.confirmed?

            ar.save!
            update_columns(last_seen_at: now, location_confirmed: ar.confirmed?)
            take_attendance
        end
    end

    # 2) Confirm attendance (set confirmed: true for the current hour),
    #    then backfill contiguous previous hours while ip+location match.
    def confirm_attendance!
        now = Time.current
        cutoff = now.beginning_of_hour

        ApplicationRecord.transaction do
            ar = attendance_records.where(cutoff: cutoff).first_or_initialize
            ar.confirmed = true
            ar.location ||= last_known_location
            ar.save!

            update_columns(
                last_seen_at: now,
                location_confirmed: true)
            take_attendance

            backfill_contiguous_confirmations!(ar)
        end
    end

    # 3) Set/update the current location string.
    #    - If location changes, confirmation is reset to false.
    #    - If still false, we may infer confirmation from the previous hour when ip+location match.
    def set_current_location(location:)
        now = Time.current
        cutoff = now.beginning_of_hour

        ApplicationRecord.transaction do
            ar = attendance_records.where(cutoff: cutoff).first_or_initialize
            location_changed = ar.location != location
            ar.location = location

            # reset confirmation if location changed
            ar.confirmed = false if location_changed

            infer_confirmation_from_previous!(ar, cutoff) unless ar.confirmed?

            ar.save!
            update_columns(last_seen_at: now)
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

    # If the previous hour was confirmed and ip+location match, set current confirmed=true.
    def infer_confirmation_from_previous!(record, cutoff)
        prev = attendance_records.find_by(cutoff: cutoff - 1.hour)
        if record.location.blank? && prev&.location.present?
            record.location = prev.location
        end
        if prev&.confirmed? &&
           prev.location.present? && prev.location == record.location &&
           prev.ip.present?       && prev.ip       == record.ip
            record.confirmed = true
        end
    end

    # Walk backwards hour-by-hour, flipping confirmed=true while ip+location match and hours are contiguous.
    def backfill_contiguous_confirmations!(current_record)
        return unless current_record.confirmed?

        current_location = current_record.location
        current_ip       = current_record.ip
        prev_cutoff      = current_record.cutoff - 1.hour

        loop do
            prev = attendance_records.find_by(cutoff: prev_cutoff)
            break unless prev
            break unless prev.location == current_location && prev.ip == current_ip

            prev.update_columns(confirmed: true) unless prev.confirmed?
            prev_cutoff -= 1.hour
        end
    end

end
