require "test_helper"

# Mapping the room is done under time pressure by several people at once, so
# the controller's job is largely to refuse the changes that would quietly lose
# information: double-booking a table, switching off an occupied one, or
# shrinking the room out from under someone.
#
class AdminExamsControllerTest < ActionController::TestCase

    tests Admin::ExamsController

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

    #-- the report -------------------------------------------------------------

    test "the report of an exam that was held is a pdf" do
        sign_in @admin
        @exam.update!(locked: true)
        @first.update!(seat: "1-1")

        get :report, params: { id: @exam.id }

        assert_response :success
        assert_equal "application/pdf", response.media_type
        assert response.body.start_with?("%PDF")
    end

    test "there is no report of a practice exam or one without placement" do
        sign_in @admin
        @first.update!(seat: "1-1")

        get :report, params: { id: @exam.id }
        assert_response :not_found

        @exam.update!(locked: true)
        @first.update!(seat: nil)

        get :report, params: { id: @exam.id }
        assert_response :not_found
    end

    #-- the page ---------------------------------------------------------------

    test "a bare link lands on whichever tab was used last" do
        sign_in @admin

        get :show, params: { id: @exam.id, view: "list" }
        assert_response :success
        assert_equal "list", session[:exam_view]

        get :show, params: { id: @exam.id }
        assert_response :success, "the list is where it left off"
    end

    test "a bare link goes to the room by default" do
        sign_in @admin

        get :show, params: { id: @exam.id }

        assert_redirected_to admin_exam_room_path(@exam)
    end

    test "locking a student from the room redraws the room" do
        sign_in @admin
        @first.update!(seat: "1-1")

        patch :toggle_student, params: { id: @exam.id, submit_id: @first.id,
            view: "room", phase: "overview", submit: { locked: "1" } }

        assert @first.reload.locked?
        assert_redirected_to admin_exam_room_path(@exam, phase: "overview")
    end

    test "locking a student from the list says nothing back" do
        sign_in @admin

        patch :toggle_student, params: { id: @exam.id, submit_id: @first.id, submit: { locked: "1" } }

        assert @first.reload.locked?
        assert_response :ok
        assert_empty @response.body
    end

end
