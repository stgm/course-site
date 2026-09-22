require "test_helper"

# Mapping the room is done under time pressure by several people at once, so
# the controller's job is largely to refuse the changes that would quietly
# lose information: double-booking a table, switching off an occupied one, or
# taking away a side of the room that somebody is sitting on.
#
class Admin::Exams::RoomsControllerTest < ActionController::TestCase

    tests Admin::Exams::RoomsController

    setup do
        @admin = users(:test_user)
        @admin.update!(role: :admin)

        @pset = psets(:mario)
        @exam = Exam.create!(pset: @pset, locked: false, config: {})
        @exam.room = { "rows" => 3, "cols" => 3 }
        @exam.room_phase = "place"
        @exam.save!

        # a third student, created here rather than added to the shared
        # fixtures: User::FinalGradeCalculatorTest picks its subjects with
        # User.first and User.second, so an extra fixture changes what it tests
        @third = User.create!(name: "Sam Derde", mail: "test3@example.com")

        @first = Submit.create!(user: users(:test_user_2), pset: @pset, submitted_at: 1.minute.ago)
        @second = Submit.create!(user: @third, pset: @pset, submitted_at: 1.minute.ago)

        Settings.course = { "short_name" => "TESTCOURSE" }
    end

    teardown do
        Settings.course = {}
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end

    #-- the page ---------------------------------------------------------------

    test "the room opens on the phase the exam has reached" do
        sign_in @admin

        get :show, params: { exam_id: @exam.id }
        assert_response :success
        assert_no_match "Indent every second row", @response.body, "the place phase has no layout controls"

        get :show, params: { exam_id: @exam.id, phase: "define" }
        assert_match "Indent every second row", @response.body, "a phase in the URL is a step back"
    end

    test "visiting the room is remembered for the next bare link" do
        sign_in @admin

        get :show, params: { exam_id: @exam.id }

        assert_equal "room", session[:exam_view]
    end

    #-- placing ----------------------------------------------------------------

    test "placing a student seats them" do
        sign_in @admin

        patch :place, params: { exam_id: @exam.id, seat: "1-2", submit_id: @first.id }

        assert_redirected_to admin_exam_room_path(@exam, phase: "place")
        assert_equal "1-2", @first.reload.seat
    end

    test "placing a seated student again moves them rather than duplicating" do
        sign_in @admin
        @first.update!(seat: "1-1")

        patch :place, params: { exam_id: @exam.id, seat: "3-3", submit_id: @first.id }

        assert_equal "3-3", @first.reload.seat
        assert_nil Submit.find_by(pset: @pset, seat: "1-1")
    end

    test "placing into an occupied seat leaves both students alone" do
        sign_in @admin
        @first.update!(seat: "2-2")

        patch :place, params: { exam_id: @exam.id, seat: "2-2", submit_id: @second.id }

        assert_equal "2-2", @first.reload.seat
        assert_nil @second.reload.seat
        assert_match "taken by", flash[:alert]
    end

    test "replacing an occupant leaves that occupant unplaced" do
        sign_in @admin
        @first.update!(seat: "2-2")

        patch :place, params: { exam_id: @exam.id, seat: "2-2", submit_id: @second.id, replace: "1" }

        assert_nil @first.reload.seat
        assert_equal "2-2", @second.reload.seat
    end

    test "dragging one student onto another trades their tables" do
        sign_in @admin
        @first.update!(seat: "1-1")
        @second.update!(seat: "3-3")

        patch :place, params: { exam_id: @exam.id, seat: "3-3", submit_id: @first.id, swap: "1" }

        assert_equal "3-3", @first.reload.seat
        assert_equal "1-1", @second.reload.seat, "neither of them leaves the room"
        assert_match "swapped tables", flash[:notice]
    end

    test "dragging a student onto an empty table just moves them" do
        sign_in @admin
        @first.update!(seat: "1-1")

        patch :place, params: { exam_id: @exam.id, seat: "3-3", submit_id: @first.id, swap: "1" }

        assert_equal "3-3", @first.reload.seat
        assert_nil Submit.find_by(pset: @pset, seat: "1-1")
    end

    test "a swap without a table to swap back to is still refused" do
        sign_in @admin
        @first.update!(seat: "2-2")

        patch :place, params: { exam_id: @exam.id, seat: "2-2", submit_id: @second.id, swap: "1" }

        assert_equal "2-2", @first.reload.seat
        assert_nil @second.reload.seat
        assert_match "taken by", flash[:alert]
    end

    test "placing nobody clears the table" do
        sign_in @admin
        @first.update!(seat: "1-1")

        patch :place, params: { exam_id: @exam.id, seat: "1-1", submit_id: "" }

        assert_nil @first.reload.seat
    end

    test "a table outside the room cannot be used" do
        sign_in @admin

        patch :place, params: { exam_id: @exam.id, seat: "9-9", submit_id: @first.id }

        assert_nil @first.reload.seat
        assert_match "not part of the room", flash[:alert]
    end

    test "a table that is switched off cannot be used" do
        sign_in @admin
        @exam.room = { "disabled" => [ "1-1" ] }
        @exam.save!

        patch :place, params: { exam_id: @exam.id, seat: "1-1", submit_id: @first.id }

        assert_nil @first.reload.seat
        assert_match "switched off", flash[:alert]
    end

    test "the dimension boxes are only there while the room is empty" do
        sign_in @admin

        get :show, params: { exam_id: @exam.id, phase: "define" }
        assert_match "Apply", @response.body
        assert_match "room_rows", @response.body

        @first.update!(seat: "1-1")
        get :show, params: { exam_id: @exam.id, phase: "define" }

        assert_no_match "room_rows", @response.body, "the size is changed with the + and - buttons now"
        assert_no_match "Apply", @response.body, "the indent saves itself"
        assert_match "room_stagger", @response.body
    end

    #-- the layout -------------------------------------------------------------

    test "the layout saves dimensions, the indent and the column labels" do
        sign_in @admin

        patch :layout, params: { exam_id: @exam.id,
            room: { rows: "4", cols: "5", stagger: "1", labels: { "1" => "Raam", "2" => "" } } }

        @exam.reload
        assert_equal 4, @exam.room_rows
        assert_equal 5, @exam.room_cols
        assert @exam.room_stagger?
        assert_equal "Raam", @exam.column_label(1)
        assert_equal "B", @exam.column_label(2), "a blank label falls back to the default"
    end

    test "switching a table off and on again" do
        sign_in @admin

        patch :layout, params: { exam_id: @exam.id, room: { toggle_seat: "2-1" } }
        assert_includes @exam.reload.disabled_seats, "2-1"

        patch :layout, params: { exam_id: @exam.id, room: { toggle_seat: "2-1" } }
        assert_not_includes @exam.reload.disabled_seats, "2-1"
    end

    test "a table with somebody at it cannot be switched off" do
        sign_in @admin
        @first.update!(seat: "2-1")

        patch :layout, params: { exam_id: @exam.id, room: { toggle_seat: "2-1" } }

        assert_empty @exam.reload.disabled_seats
        assert_match "Remove them from the table", flash[:alert]
    end

    test "the room cannot be made smaller once anybody is at a table" do
        sign_in @admin
        @first.update!(seat: "1-1") # placed well inside the smaller room

        patch :layout, params: { exam_id: @exam.id, room: { rows: "2", cols: "3" } }

        assert_equal 3, @exam.reload.room_rows
        assert_equal "1-1", @first.reload.seat
        assert_match "cannot be made smaller", flash[:alert]
    end

    test "the room still grows while students are placed" do
        sign_in @admin
        @first.update!(seat: "1-1")

        patch :layout, params: { exam_id: @exam.id, room: { rows: "5", cols: "3" } }

        assert_equal 5, @exam.reload.room_rows
        assert_equal "1-1", @first.reload.seat
    end

    test "an empty room shrinks freely" do
        sign_in @admin

        patch :layout, params: { exam_id: @exam.id, room: { rows: "2", cols: "2" } }

        assert_equal 2, @exam.reload.room_rows
        assert_equal 2, @exam.room_cols
    end

    test "the add buttons grow the room and move placed students along" do
        sign_in @admin
        @first.update!(seat: "1-1")

        patch :layout, params: { exam_id: @exam.id, room: { add: "back" } }
        assert_equal 4, @exam.reload.room_rows
        assert_equal "1-1", @first.reload.seat

        patch :layout, params: { exam_id: @exam.id, room: { add: "front" } }
        assert_equal 5, @exam.reload.room_rows
        assert_equal "2-1", @first.reload.seat
        assert_match "moved back a row", flash[:notice]

        patch :layout, params: { exam_id: @exam.id, room: { add: "left" } }
        assert_equal 4, @exam.reload.room_cols
        assert_equal "2-2", @first.reload.seat
    end

    test "the minus buttons take a side off and move the rest along" do
        sign_in @admin
        @first.update!(seat: "2-2")

        patch :layout, params: { exam_id: @exam.id, room: { remove: "back" } }
        assert_equal 2, @exam.reload.room_rows
        assert_equal "2-2", @first.reload.seat

        patch :layout, params: { exam_id: @exam.id, room: { remove: "left" } }
        assert_equal 2, @exam.reload.room_cols
        assert_equal "2-1", @first.reload.seat
        assert_match "moved one column along", flash[:notice]
    end

    test "a side with somebody on it is not removed" do
        sign_in @admin
        @first.update!(seat: "1-1")

        patch :layout, params: { exam_id: @exam.id, room: { remove: "front" } }

        assert_equal 3, @exam.reload.room_rows
        assert_equal "1-1", @first.reload.seat
        assert_match "sitting on that side", flash[:alert]
    end

    test "the last row is not removed" do
        sign_in @admin
        @exam.room = { "rows" => 1 }
        @exam.save!

        patch :layout, params: { exam_id: @exam.id, room: { remove: "back" } }

        assert_equal 1, @exam.reload.room_rows
        assert_match "at least one row", flash[:alert]
    end

    test "the room stops growing at the limit" do
        sign_in @admin
        @exam.room = { "rows" => Exam::ROOM_LIMIT }
        @exam.save!

        patch :layout, params: { exam_id: @exam.id, room: { add: "back" } }

        assert_equal Exam::ROOM_LIMIT, @exam.reload.room_rows
        assert_match "as big as it goes", flash[:alert]
    end

    test "only a real side of the room can be added to" do
        sign_in @admin

        patch :layout, params: { exam_id: @exam.id, room: { add: "diagonally" } }

        assert_equal 3, @exam.reload.room_rows
        assert_match "not a side of the room", flash[:alert]
    end

    #-- the phases -------------------------------------------------------------

    test "stepping forward records the phase" do
        sign_in @admin

        patch :phase, params: { exam_id: @exam.id, phase: "overview" }

        assert_redirected_to admin_exam_room_path(@exam, phase: "overview")
        assert_equal "overview", @exam.reload.room_phase
    end

    test "stepping back keeps the progress and the placements" do
        sign_in @admin
        @first.update!(seat: "1-1")
        @exam.room_phase = "overview"
        @exam.save!

        patch :phase, params: { exam_id: @exam.id, phase: "define" }

        assert_redirected_to admin_exam_room_path(@exam, phase: "define")
        assert_equal "overview", @exam.reload.room_phase, "stepping back does not undo the progress"
        assert_equal "1-1", @first.reload.seat
    end

    test "a room with no tables cannot be left" do
        sign_in @admin
        @exam.room = { "disabled" => @exam.seats }
        @exam.save!

        patch :phase, params: { exam_id: @exam.id, phase: "place" }

        assert_redirected_to admin_exam_room_path(@exam, phase: "define")
        assert_match "no tables", flash[:alert]
    end

    test "only admins get at the room" do
        sign_in users(:test_user_2)

        patch :place, params: { exam_id: @exam.id, seat: "1-1", submit_id: @first.id }

        assert_response :forbidden
        assert_nil @first.reload.seat
    end

end
