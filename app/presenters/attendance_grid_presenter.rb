class AttendanceGridPresenter
    attr_reader :config, :first_attendance, :last_attendance, :counts, :confirmed_counts

    def initialize(config: nil, first_attendance: nil, last_attendance: nil, counts: {}, confirmed_counts: {})
        @config           = config
        @first_attendance = to_date_or_nil(first_attendance)
        @last_attendance  = to_date_or_nil(last_attendance)
        # Expect Date keys; coerce if needed
        @counts = counts.transform_keys { |k| to_date_or_nil(k) }.compact
        @confirmed_counts = confirmed_counts.transform_keys { |k| to_date_or_nil(k) }.compact
    end

    # ---------- Public API used by the partial ----------

    def weeks
        return 0 unless start_date && end_date
        ((end_date - start_date).to_i / 7) + 1
    end

    # Offset relative to config start; if no config, no offset.
    def offset
        return 0 unless config_start && start_date
        ((start_date - config_start).to_i / 7)
    end

    def week_range
        return (0...0) if weeks <= 0
        (1 + offset)..(weeks + offset)
    end

    def day_abbrs_mo_su
        Date::ABBR_DAYNAMES.rotate(1) # Mon..Sun
    end

    def week_indices
        0...weeks
    end

    def day_indices
        0..6 # Mon..Sun
    end

    def date_for(week_index, day_index)
        return nil unless start_date
        start_date + (week_index * 7 + day_index)
    end

    def attendance_count(date)
        counts[date] || 0
    end

    def confirmed_attendance_count(date)
        confirmed_counts[date] || 0
    end

    def hours_label(date)
        hrs = attendance_count(date)
        chrs = confirmed_attendance_count(date)
        unit = "h"
        label = "#{hrs}#{unit}"
        label << "(#{chrs}#{unit})" if chrs >0
        label
    end

    # Simple color ramp (inline style); adjust as desired
    def attendance_style(date)
        c = attendance_count(date)
        f = confirmed_attendance_count(date)
        return "background-color: #f8f9fa;" if c <= 0

        max = (counts.values.max || 1).to_f
        t = [ [ c / max, 0.15 ].max, 1.0 ].min
        if f == 0
            "background-color: rgba(25, 135, 84, #{t});"
        else
            "background-color: rgba(25, 135, 194, #{c});"
        end
    end

    def box_style(date)
        base = "--bs-border-radius:2px;"
        base << attendance_style(date)

        # thicker border for today
        if today?(date)
            base << "--bs-border-color: black; --bs-border-width: 3px;"
        else
            base << "--bs-border-width: 0;"
        end

        base
    end

    # ---------- Internals ----------

    def start_date
        return @start_date if defined?(@start_date)
        base_start = config_start || inferred_start_from_attendance
        # attendance can extend earlier
        fa = first_attendance&.beginning_of_week(:monday)
        @start_date = [ base_start, fa ].compact.min
    end

    def end_date
        return @end_date if defined?(@end_date)
        base_end = config_end || inferred_end_from_attendance
        # attendance can extend later
        la = last_attendance&.end_of_week(:monday)
        @end_date = [ base_end, la ].compact.max
    end

    # Parse config dates if present; nil-safe.
    def config_start
        return nil unless config_present?
        str = config["start_date"] rescue nil
        return nil if str.blank?
        Date.strptime(str, "%d/%m/%y").beginning_of_week(:monday)
      rescue ArgumentError
          nil
    end

    def config_end
        return nil unless config_present?
        str = config["end_date"] rescue nil
        return nil if str.blank?
        Date.strptime(str, "%d/%m/%y").end_of_week(:sunday)
      rescue ArgumentError
          nil
    end

  # private

    def config_present?
        config.respond_to?(:[]) && config.is_a?(Hash)
    end

    def inferred_start_from_attendance
        d = attendance_dates.min
        d&.beginning_of_week(:monday)
    end

    def inferred_end_from_attendance
        d = attendance_dates.max
        d&.end_of_week(:sunday)
    end

    def attendance_dates
        dates = []
        dates << first_attendance if first_attendance
        dates << last_attendance if last_attendance
        dates.concat(counts.keys) unless counts.empty?
        dates.compact
    end

    def to_date_or_nil(value)
        case value
        when Date then value
        when Time, DateTime then value.to_date
        when String
            # Be conservative; try ISO first, then fall back to a couple formats you might use.
            Date.iso8601(value) rescue (Date.parse(value) rescue nil)
        else
            nil
        end
    end

    def today?(date)
        date == Date.current
    end
end
