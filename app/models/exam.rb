class Exam < ApplicationRecord

    belongs_to :pset
    delegate :name, to: :pset

    serialize :config, coder: YAML, type: Hash

    # A "practice" exam is never listed as an exam: students reach it through
    # tutorials, or directly once it is unlocked.
    enum :kind, { exam: "exam", practice: "practice" }

    has_many :tutorials, dependent: :destroy

    # How long after their last editor postback a student still counts as
    # taking this exam. The same window the session overview calls "active".
    ACTIVE_WINDOW = 5.hours

    ROOM_DEFAULTS = {
        "rows" => 6,
        "cols" => 8,
        "stagger" => false,
        "disabled" => [],
        "labels" => {},
        "phase" => "define"
    }.freeze

    ROOM_PHASES = %w[define place overview].freeze

    # Row 1 is the front of the room and column 1 its left-hand side, so a row
    # added at the front or a column added on the left renumbers everything
    # that is already there.
    ROOM_SIDES = %w[front back left right].freeze

    ROOM_LIMIT = 40

    # Tells whether exam mode is on and this is the exam it is set to.
    def current?
        Settings.registration_phase == "exam" && Settings.exam_current == id
    end

    def allow_taking?
        # in exam mode, only show "current" exams
        current? ||
        # outside of exam mode, only show unlocked exams (e.g. practice)
        (Settings.registration_phase != "exam" && !self.locked?)
    end

    # Tells whether this user may start a session although the exam is locked:
    # seniors, staff for a practice exam, and members of a tutorial for it.
    def lock_exempt?(user)
        user.senior? || (practice? && user.staff?) || tutorial_member?(user)
    end

    # Tells whether the lock keeps this user from starting a session. The
    # exam that exam mode is set to is never locked, and the exemptions in
    # lock_exempt? apply.
    def locked_for?(user)
        locked? && !current? && !lock_exempt?(user)
    end

    # Tells whether this exam has taken place: it is a real exam, it is not the
    # one running now, and somebody was registered at a table.
    def held?
        locked? && Settings.exam_current != id && pset.submits.where.not(seat: nil).exists?
    end

    # lock the submit of anyone who took this exam
    # so if we re-open the exam they cannot automatically open it
    def lock_existing_students
        pset.submits.update_all(locked: true)
    end

    def open_for_user?(user)
        @open_for_user ||= {}
        @open_for_user[user.id] ||= begin
            submit = Submit.find_by(user: user, pset: pset)
            user.admin? || (allow_taking? || lock_exempt?(user)) && (submit.nil? || !submit.locked?)
        end
    end

    # Tells whether this user claimed a tutorial for this exam. A claim stays valid
    # when the tutorial is closed, but never counts while exam mode is active.
    def tutorial_member?(user)
        Settings.registration_phase != "exam" &&
            TutorialMembership.joins(:tutorial).exists?(user_id: user.id, tutorials: { exam_id: id })
    end

    def name_with_code
        if eval_code.present?
            "#{name.titleize} (#{eval_code})"
        else
            name.titleize
        end
    end

    #-- who is taking this exam ------------------------------------------------

    # Everyone who has started this exam recently enough to be in the room now.
    def active_submits
        pset.submits.includes(:user).where("submitted_at >= ?", ACTIVE_WINDOW.ago)
    end

    def stale_submits
        pset.submits.includes(:user).where("submitted_at < ?", ACTIVE_WINDOW.ago)
    end

    def placed_submits
        active_submits.where.not(seat: nil)
    end

    # Students who are logged in and taking the exam but were not found at any
    # table. These are the ones to go and look for.
    def unplaced_submits
        active_submits.where(seat: nil)
    end

    # Maps "row-col" to the submit sitting there, for the seats that are taken.
    def seating
        placed_submits.index_by(&:seat)
    end

    #-- the room ---------------------------------------------------------------

    # Describes the room as rows, columns and which tables are really there.
    def room
        ROOM_DEFAULTS.merge(config["room"] || {})
    end

    def room=(attrs)
        config["room"] = room.merge(attrs.stringify_keys)
        config_will_change!
    end

    def room_rows
        room["rows"].to_i
    end

    def room_cols
        room["cols"].to_i
    end

    def room_stagger?
        ActiveModel::Type::Boolean.new.cast(room["stagger"]).present?
    end

    def room_phase
        phase = room["phase"].to_s
        ROOM_PHASES.include?(phase) ? phase : "define"
    end

    def room_phase=(phase)
        phase = phase.to_s
        raise ArgumentError, "unknown room phase #{phase}" unless ROOM_PHASES.include?(phase)
        self.room = { "phase" => phase }
    end

    def room_defining?
        room_phase == "define"
    end

    def room_placing?
        room_phase == "place"
    end

    def room_overview?
        room_phase == "overview"
    end

    def disabled_seats
        Array(room["disabled"])
    end

    def seat_disabled?(seat)
        disabled_seats.include?(seat.to_s)
    end

    def seat_enabled?(seat)
        seat_within_room?(seat) && !seat_disabled?(seat)
    end

    def enabled_seats
        seats.reject { |seat| seat_disabled?(seat) }
    end

    # Every table in the room, in reading order.
    def seats
        (1..room_rows).flat_map do |row|
            (1..room_cols).map { |col| Exam.seat_for(row, col) }
        end
    end

    def seat_within_room?(seat)
        row, col = Exam.seat_coordinates(seat)
        return false if row.nil?
        row.between?(1, room_rows) && col.between?(1, room_cols)
    end

    # The name a column carries in the room itself, e.g. the letter taped to the
    # front table. Falls back to A, B, ... Z, AA, AB when nothing is set.
    def column_label(col)
        label = room["labels"][col.to_s].presence
        label || Exam.default_column_label(col)
    end

    # What staff call a table out loud, e.g. "B3".
    def seat_label(seat)
        row, col = Exam.seat_coordinates(seat)
        return seat.to_s if row.nil?
        "#{column_label(col)}#{row}"
    end

    # Adds one row or column to the given side of the room, taking the tables
    # and the students at them along when the near edge moves.
    def grow_room!(side)
        raise ArgumentError, "unknown side #{side}" unless ROOM_SIDES.include?(side.to_s)

        transaction do
            case side.to_s
            when "back"  then self.room = { "rows" => room_rows + 1 }
            when "right" then self.room = { "cols" => room_cols + 1 }
            when "front" then shift_room(rows: 1)
            when "left"  then shift_room(cols: 1)
            end
            save!
        end
    end

    # Takes one row or column away from the given side. Only ever called for a
    # side with nobody at it, so no placement is lost; removing the front row
    # or the left-hand column moves the rest of the room up to fill the gap.
    def shrink_room!(side)
        raise ArgumentError, "unknown side #{side}" unless ROOM_SIDES.include?(side.to_s)

        transaction do
            case side.to_s
            when "back"  then drop_far_edge(rows: 1)
            when "right" then drop_far_edge(cols: 1)
            when "front" then drop_near_edge(rows: 1)
            when "left"  then drop_near_edge(cols: 1)
            end
            save!
        end
    end

    # The tables along one side of the room.
    def edge_seats(side)
        case side.to_s
        when "front" then (1..room_cols).map { |col| Exam.seat_for(1, col) }
        when "back"  then (1..room_cols).map { |col| Exam.seat_for(room_rows, col) }
        when "left"  then (1..room_rows).map { |row| Exam.seat_for(row, 1) }
        when "right" then (1..room_rows).map { |row| Exam.seat_for(row, room_cols) }
        else []
        end
    end

    # Who would be lost if this side were taken away. Stale submits count as
    # much as active ones: their seat is still a placement.
    def edge_occupants(side)
        pset.submits.includes(:user).where(seat: edge_seats(side))
    end

    def room_at_limit?(side)
        if side.to_s.in?([ "front", "back" ])
            room_rows >= ROOM_LIMIT
        else
            room_cols >= ROOM_LIMIT
        end
    end

    def room_at_minimum?(side)
        if side.to_s.in?([ "front", "back" ])
            room_rows <= 1
        else
            room_cols <= 1
        end
    end

    def can_shrink_room?(side)
        !room_at_minimum?(side) && edge_occupants(side).none?
    end

    def self.seat_for(row, col)
        "#{row}-#{col}"
    end

    # Splits "3-5" into [3, 5], or [nil, nil] when it is not a seat.
    def self.seat_coordinates(seat)
        match = seat.to_s.match(/\A(\d+)-(\d+)\z/)
        return [ nil, nil ] if match.nil?
        [ match[1].to_i, match[2].to_i ]
    end

    # Moves the whole room one place along so that a new row or column can
    # appear at the near edge. Seats are renumbered from the far edge inwards,
    # so a seat is never briefly the same as one that has yet to move and the
    # unique index is never violated halfway through.
    def shift_room(rows: 0, cols: 0)
        seated = pset.submits.where.not(seat: nil).to_a
        seated.sort_by! do |submit|
            row, col = Exam.seat_coordinates(submit.seat)
            -(rows.positive? ? row.to_i : col.to_i)
        end

        seated.each do |submit|
            submit.update!(seat: Exam.shift_seat(submit.seat, rows: rows, cols: cols))
        end

        self.room = {
            "rows" => room_rows + rows,
            "cols" => room_cols + cols,
            "disabled" => disabled_seats.map { |seat| Exam.shift_seat(seat, rows: rows, cols: cols) },
            # a column keeps the name taped to it, so the labels move along too
            "labels" => room["labels"].to_h.transform_keys { |col| (col.to_i + cols).to_s }
        }
    end

    # Removes the far row or column, which needs no renumbering: the tables
    # that go are the highest-numbered ones.
    def drop_far_edge(rows: 0, cols: 0)
        gone = edge_seats(rows.positive? ? "back" : "right")

        self.room = {
            "rows" => room_rows - rows,
            "cols" => room_cols - cols,
            "disabled" => disabled_seats - gone,
            "labels" => cols.positive? ? room["labels"].to_h.except(room_cols.to_s) : room["labels"]
        }
    end

    # Removes the front row or the left-hand column and moves everything else
    # up to fill the gap. Seats are renumbered from the near edge outwards, so
    # a seat is never briefly the same as one that has yet to move.
    def drop_near_edge(rows: 0, cols: 0)
        gone = edge_seats(rows.positive? ? "front" : "left")

        seated = pset.submits.where.not(seat: nil).to_a
        seated.sort_by! do |submit|
            row, col = Exam.seat_coordinates(submit.seat)
            rows.positive? ? row.to_i : col.to_i
        end
        seated.each do |submit|
            submit.update!(seat: Exam.shift_seat(submit.seat, rows: -rows, cols: -cols))
        end

        labels = room["labels"].to_h
        labels = labels.except("1").transform_keys { |col| (col.to_i - 1).to_s } if cols.positive?

        self.room = {
            "rows" => room_rows - rows,
            "cols" => room_cols - cols,
            "disabled" => (disabled_seats - gone).map { |seat| Exam.shift_seat(seat, rows: -rows, cols: -cols) },
            "labels" => labels
        }
    end

    def self.shift_seat(seat, rows: 0, cols: 0)
        row, col = seat_coordinates(seat)
        return seat if row.nil?
        seat_for(row + rows, col + cols)
    end

    # Counts like a spreadsheet does: A..Z, then AA, AB and so on.
    def self.default_column_label(col)
        letters = []
        n = col.to_i
        while n > 0
            n, remainder = (n - 1).divmod(26)
            letters.unshift((65 + remainder).chr)
        end
        letters.join
    end
end
