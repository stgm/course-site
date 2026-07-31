require "test_helper"

# The archival phase is what "the course is closed" means: the exports live behind it, and
# nobody but an admin should still be walking around. The phase used to be checked only
# while logging in, so the lockout of sessions that predate the switch is asserted here
# alongside the tab itself.
#
class ArchivingControllerTest < ActionController::TestCase

    tests Admin::ArchivingController

    setup do
        # the modal's tab strip reads the current schedule's grading config
        @schedule = Schedule.create!(name: "Test schedule")

        @admin = users(:test_user)
        @admin.update!(role: :admin, schedule: @schedule)

        @student = users(:test_user_2)
        @student.update!(role: :student, student_number: "12345678", status: :active)

        Settings.registration_phase = "during"
    end

    teardown do
        Settings.registration_phase = "before"
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end


    test "shows the phase step and the exports to an admin" do
        sign_in(@admin)
        get :index

        assert_response :success
        assert_match "Put course in archival phase", response.body
        assert_match "Download course archive", response.body
    end

    test "reports the phase instead of the button once archived" do
        Settings.registration_phase = "archival"

        sign_in(@admin)
        get :index

        assert_response :success
        assert_no_match(/Put course in archival phase/, response.body)
        assert_match "The course is in archival phase", response.body
    end

    test "is refused for non-admins" do
        sign_in(@student)
        get :index

        assert_response :forbidden
    end

    test "drops a non-admin session that predates the switch to archival" do
        sign_in(@student)
        Settings.registration_phase = "archival"

        get :index

        assert_redirected_to root_path
        assert_nil session[:user_id], "the archived course must not keep a student signed in"
    end

    test "keeps an admin signed in while archived" do
        Settings.registration_phase = "archival"

        sign_in(@admin)
        get :index

        assert_response :success
        assert_equal @admin.id, session[:user_id]
    end

end
