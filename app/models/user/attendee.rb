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
            ar.ip = ip
            infer_from_previous!(ar, cutoff) unless ar.confirmed?
            ar.save!

            # if already confirmed and ip now known, try to confirm earlier hours as well
            backfill_contiguous_confirmations!(ar)

            update_columns(
                last_seen_at: now,
                location_confirmed: ar.confirmed?)
            take_attendance
        end
    end

    # 2) Confirm attendance (set confirmed: true for the current hour),
    #    then backfill contiguous previous hours where ip+location match.
    # Called when staff checks student in from question queue (hands).
    #
    # Note that the IP may not be filled if confirmation comes when student
    # has not loaded the site this hour. However, in that case the record
    # may be augmented as soon as the student pings the site.
    def confirm_attendance!
        now = Time.current
        cutoff = now.beginning_of_hour

        ApplicationRecord.transaction do
            ar = attendance_records.where(cutoff: cutoff).first_or_initialize
            ar.confirmed = true
            ar.save!

            # try to confirm earlier hours as well
            backfill_contiguous_confirmations!(ar)

            update_columns(
                last_seen_at: now,
                location_confirmed: true)
            take_attendance
        end
    end

    # 3) Set/update the current location string.
    # Called when user reports location from the popup.
    #    - If location changes, confirmation is reset to false.
    def set_current_location(location:)
        now = Time.current
        cutoff = now.beginning_of_hour

        ApplicationRecord.transaction do
            ar = attendance_records.where(cutoff: cutoff).first_or_initialize

            ar.location = location
            if ar.location_changed?
                ar.confirmed = false
                update_columns(location_confirmed: false)
            end
            ar.save!
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
    def infer_from_previous!(record, cutoff)
        prev = attendance_records.find_by(cutoff: cutoff - 1.hour)

        # copy location from previous hour if still same IP
        if prev&.ip.present? &&
           prev.ip == record.ip &&
           record.location.blank? &&
           prev&.location.present?
            record.location = prev.location
        end

        # copy confirmation from previous if same IP and same location
        # (e.g. if student manually reported new location we need manual confirmation)
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
