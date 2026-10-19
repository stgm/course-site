require "test_helper"

# The room accessors on Exam are what the map view and its controller are built
# on: everything about the room is derived from one serialized hash, so the
# defaults and the coordinate arithmetic are worth pinning down.
#
class ExamTest < ActiveSupport::TestCase

    setup do
        @exam = Exam.create!(pset: psets(:mario), locked: false, config: {})

        # a third student, created here rather than added to the shared
        # fixtures: User::FinalGradeCalculatorTest picks its subjects with
        # User.first and User.second, so an extra fixture changes what it tests
        @third = User.create!(name: "Sam Derde", mail: "test3@example.com")
    end

    test "a new exam starts in the define phase with a default room" do
        assert_equal "define", @exam.room_phase
        assert @exam.room_defining?
        assert_equal 6, @exam.room_rows
        assert_equal 8, @exam.room_cols
        assert_not @exam.room_stagger?
        assert_empty @exam.disabled_seats
    end

    test "the room merges what is stored over the defaults" do
        @exam.room = { "rows" => 4, "stagger" => true }
        @exam.save!

        assert_equal 4, @exam.reload.room_rows
        assert_equal 8, @exam.room_cols, "untouched settings keep their default"
        assert @exam.room_stagger?
    end

    test "seats run in reading order and know whether they are in the room" do
        @exam.room = { "rows" => 2, "cols" => 3 }

        assert_equal [ "1-1", "1-2", "1-3", "2-1", "2-2", "2-3" ], @exam.seats
        assert @exam.seat_within_room?("2-3")
        assert_not @exam.seat_within_room?("3-1")
        assert_not @exam.seat_within_room?("not a seat")
    end

    test "a disabled seat is not enabled and drops out of the enabled seats" do
        @exam.room = { "rows" => 1, "cols" => 2, "disabled" => [ "1-1" ] }

        assert @exam.seat_disabled?("1-1")
        assert_not @exam.seat_enabled?("1-1")
        assert_equal [ "1-2" ], @exam.enabled_seats
    end

    test "columns are labelled like a spreadsheet unless a label is set" do
        assert_equal "A", Exam.default_column_label(1)
        assert_equal "Z", Exam.default_column_label(26)
        assert_equal "AA", Exam.default_column_label(27)
        assert_equal "AB", Exam.default_column_label(28)

        @exam.room = { "labels" => { "2" => "Raam" } }
        assert_equal "Raam", @exam.column_label(2)
        assert_equal "A", @exam.column_label(1)
    end

    test "a seat is named after its column label and row number" do
        assert_equal "B3", @exam.seat_label("3-2")

        @exam.room = { "labels" => { "2" => "Raam" } }
        assert_equal "Raam3", @exam.seat_label("3-2")
    end

    test "the phase only moves between the three known values" do
        @exam.room_phase = "place"
        assert @exam.room_placing?

        assert_raises(ArgumentError) { @exam.room_phase = "somewhere else" }
    end

    #-- growing the room -------------------------------------------------------

    test "adding at the back or on the right leaves everything where it is" do
        @exam.room = { "rows" => 2, "cols" => 2, "disabled" => [ "1-1" ] }
        seated = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "2-2")

        @exam.grow_room!("back")
        assert_equal 3, @exam.room_rows
        assert_equal "2-2", seated.reload.seat

        @exam.grow_room!("right")
        assert_equal 3, @exam.room_cols
        assert_equal "2-2", seated.reload.seat
        assert_equal [ "1-1" ], @exam.disabled_seats
    end

    test "adding a row at the front moves everything back a row" do
        @exam.room = { "rows" => 2, "cols" => 2, "disabled" => [ "1-1" ] }
        front = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "1-2")
        back = Submit.create!(user: users(:test_user_2), pset: @exam.pset, seat: "2-2")

        @exam.grow_room!("front")

        assert_equal 3, @exam.room_rows
        assert_equal "2-2", front.reload.seat
        assert_equal "3-2", back.reload.seat
        assert_equal [ "2-1" ], @exam.disabled_seats
        assert_empty @exam.pset.submits.where(seat: "1-2"), "the new row is empty"
    end

    test "adding a column on the left moves everything along, labels included" do
        @exam.room = { "rows" => 1, "cols" => 2, "disabled" => [ "1-1" ], "labels" => { "1" => "Raam" } }
        seated = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "1-2")

        @exam.grow_room!("left")

        assert_equal 3, @exam.room_cols
        assert_equal "1-3", seated.reload.seat
        assert_equal [ "1-2" ], @exam.disabled_seats
        assert_equal "Raam", @exam.column_label(2), "a column keeps its name when it moves"
        assert_equal "A", @exam.column_label(1)
    end

    test "a full row shifts without ever double-booking a table" do
        @exam.room = { "rows" => 3, "cols" => 1 }
        first = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "1-1")
        second = Submit.create!(user: users(:test_user_2), pset: @exam.pset, seat: "2-1")
        third = Submit.create!(user: @third, pset: @exam.pset, seat: "3-1")

        @exam.grow_room!("front")

        assert_equal [ "2-1", "3-1", "4-1" ], [ first, second, third ].map { |s| s.reload.seat }
    end

    test "removing at the back or on the right leaves everything where it is" do
        @exam.room = { "rows" => 3, "cols" => 3, "disabled" => [ "1-1", "3-3" ], "labels" => { "3" => "Deur" } }
        seated = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "1-2")

        @exam.shrink_room!("back")
        assert_equal 2, @exam.room_rows
        assert_equal "1-2", seated.reload.seat
        assert_equal [ "1-1" ], @exam.disabled_seats, "the row that went took its disabled tables with it"

        @exam.shrink_room!("right")
        assert_equal 2, @exam.room_cols
        assert_equal "1-2", seated.reload.seat
        assert_equal "C", @exam.column_label(3), "the label of the column that went is forgotten"
    end

    test "removing the front row moves everything forward a row" do
        @exam.room = { "rows" => 3, "cols" => 2, "disabled" => [ "1-1", "3-2" ] }
        seated = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "2-2")

        @exam.shrink_room!("front")

        assert_equal 2, @exam.room_rows
        assert_equal "1-2", seated.reload.seat
        assert_equal [ "2-2" ], @exam.disabled_seats
    end

    test "removing the left column moves everything along, labels included" do
        @exam.room = { "rows" => 1, "cols" => 3, "labels" => { "1" => "Raam", "2" => "Midden" } }
        seated = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "1-3")

        @exam.shrink_room!("left")

        assert_equal 2, @exam.room_cols
        assert_equal "1-2", seated.reload.seat
        assert_equal "Midden", @exam.column_label(1)
        assert_equal "B", @exam.column_label(2)
    end

    test "a full column shifts forward without ever double-booking a table" do
        @exam.room = { "rows" => 4, "cols" => 1 }
        second = Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "2-1")
        third = Submit.create!(user: users(:test_user_2), pset: @exam.pset, seat: "3-1")
        fourth = Submit.create!(user: @third, pset: @exam.pset, seat: "4-1")

        @exam.shrink_room!("front")

        assert_equal [ "1-1", "2-1", "3-1" ], [ second, third, fourth ].map { |s| s.reload.seat }
    end

    test "a side with anybody on it cannot be removed" do
        @exam.room = { "rows" => 2, "cols" => 2 }
        Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "1-1")

        assert_not @exam.can_shrink_room?("front")
        assert_not @exam.can_shrink_room?("left")
        assert @exam.can_shrink_room?("back")
        assert @exam.can_shrink_room?("right")
    end

    test "a stale student still counts as sitting on a side" do
        @exam.room = { "rows" => 2, "cols" => 2 }
        Submit.create!(user: users(:test_user), pset: @exam.pset, seat: "2-1", submitted_at: 9.hours.ago)

        assert_not @exam.can_shrink_room?("back"),
            "a seat is a placement whether or not the student is still active"
    end

    test "the last row and the last column stay" do
        @exam.room = { "rows" => 1, "cols" => 1 }

        assert @exam.room_at_minimum?("front")
        assert @exam.room_at_minimum?("right")
        assert_not @exam.can_shrink_room?("back")
    end

    test "growing sideways is refused at the limit" do
        @exam.room = { "cols" => Exam::ROOM_LIMIT }

        assert @exam.room_at_limit?("left")
        assert @exam.room_at_limit?("right")
        assert_not @exam.room_at_limit?("back")
    end

    test "only the four sides of the room can be grown" do
        assert_raises(ArgumentError) { @exam.grow_room!("upwards") }
    end

    test "placed and unplaced are drawn from the students taking the exam now" do
        here = Submit.create!(user: users(:test_user), pset: @exam.pset, submitted_at: 2.minutes.ago, seat: "1-1")
        also_here = Submit.create!(user: users(:test_user_2), pset: @exam.pset, submitted_at: 2.minutes.ago)
        long_gone = Submit.create!(user: @third, pset: @exam.pset, submitted_at: 6.hours.ago)

        assert_equal [ here ], @exam.placed_submits.to_a
        assert_equal [ also_here ], @exam.unplaced_submits.to_a
        assert_equal({ "1-1" => here }, @exam.seating)
        assert_includes @exam.stale_submits, long_gone
        assert_not_includes @exam.active_submits, long_gone
    end

    test "an exam is held when it is a real exam that is not running and has placed students" do
        assert_not @exam.held?

        @exam.update!(locked: true)
        assert_not @exam.held?

        Submit.create!(user: users(:test_user), pset: @exam.pset, submitted_at: 1.day.ago, seat: "1-1")
        assert @exam.held?

        @exam.update!(locked: false)
        assert_not @exam.held?
    end

end
