module ExamsHelper

    # How long ago the student's editor last posted, in words.
    def exam_last_seen(submit)
        return "never" if submit.submitted_at.blank?
        "#{time_ago_in_words(submit.submitted_at)} geleden"
    end

    # A short form of the same, for a table tile where there is no room for
    # "ongeveer een uur geleden".
    def exam_last_seen_short(submit)
        return "–" if submit.submitted_at.blank?
        minutes = ((Time.current - submit.submitted_at) / 60).floor
        return "nu" if minutes < 1
        return "#{minutes}m" if minutes < 60
        "#{(minutes / 60.0).round}u"
    end

    # Green while the editor is posting normally, amber when it has gone quiet,
    # red when the student has not been seen for a long time. A red table is
    # worth walking over to.
    #
    # A locked student cannot submit at all, so their last postback is bound to
    # get older and older. Warning about that would be warning about something
    # we did on purpose, so they get a state of their own instead.
    def exam_freshness(submit)
        return "locked-out" if submit.locked?
        return "cold" if submit.submitted_at.blank?
        minutes = (Time.current - submit.submitted_at) / 60
        return "warm" if minutes < 2
        return "cool" if minutes < 10
        "cold"
    end

    # The name on a table. Adds the last initial only when two placed students
    # share a first name, so the usual case stays short.
    def exam_seat_name(submit, ambiguous_first_names)
        parts = submit.user_name.to_s.split
        first = parts.first.to_s
        return first unless ambiguous_first_names.include?(first.downcase)
        [ first, parts.last.to_s.first ].compact_blank.join(" ") + "."
    end

    # First names carried by more than one of these students.
    def exam_ambiguous_first_names(submits)
        submits.map { |s| s.user_name.to_s.split.first.to_s.downcase }
               .tally
               .select { |_name, count| count > 1 }
               .keys
    end

    # The students the room map offers when a table is clicked, as the data the
    # Stimulus controller filters on.
    def exam_placeable_students(exam)
        exam.active_submits.map do |submit|
            {
                id: submit.id,
                name: submit.user_name.to_s,
                pin: submit.user&.pin,
                seat: submit.seat,
                seat_label: submit.seat.present? ? exam.seat_label(submit.seat) : nil
            }
        end
    end

end
