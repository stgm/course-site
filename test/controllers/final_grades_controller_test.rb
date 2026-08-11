require "test_helper"

class FinalGradesControllerTest < ActionController::TestCase

    tests Admin::FinalGradesController

    setup do
        Settings.grading = {
            "calculation" => {
                "final" => { "type" => "pass", "components" => [] }
            }
        }

        @schedule = Schedule.create!(name: "Test schedule")
        @pset = Pset.create!(name: "final", final: true, config: { "type" => "pass" })

        @admin = users(:test_user)
        @admin.update!(role: :admin, schedule: @schedule)

        @student = users(:test_user_2)
        @student.update!(role: :student, student_number: "12345678", status: :active, schedule: @schedule)

        @submit = @student.submits.create!(pset: @pset)
        @grade = @submit.create_grade!(grader: @admin)
        # grade and status must land in the same save: a blank grade forces status
        # back to unfinished (see Grade::Properties#unpublicize_if_no_grade)
        @grade.update!(status: :published, grade: -1)
    end

    teardown do
        Settings.grading = {}
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end

    test "index redirects to the first final grade type" do
        sign_in(@admin)
        get :index

        assert_redirected_to admin_final_grade_path("final")
    end

    test "shows a tab per final grade type with its pending count, and lists pending grades unchecked" do
        sign_in(@admin)
        get :show, params: { name: "final" }

        assert_response :success
        assert_match "final (1)", response.body
        assert_match "Pending (1)", response.body
        assert_no_match(/Already submitted/, response.body)
        assert_match @student.name, response.body
        assert_match "AVV", response.body
        assert_no_match(/type="checkbox" name="grade_ids\[\]"[^>]*checked/, response.body,
            "nothing should be pre-selected")
    end

    test "lists already-exported grades below pending ones, with an undo button" do
        @grade.update!(status: :exported, exported_at: Time.current)

        sign_in(@admin)
        get :show, params: { name: "final" }

        assert_response :success
        assert_no_match(/Pending/, response.body)
        assert_match "Already submitted (1)", response.body
        assert_match "Undo", response.body
    end

    test "export marks selected grades as exported with the given timestamp and returns xlsx" do
        sign_in(@admin)
        timestamp = "2026-01-15T10:30"

        post :export, params: { final_grade_name: "final", grade_ids: [ @grade.id ], exported_at: timestamp }, format: :xlsx

        assert_response :success
        @grade.reload
        assert @grade.exported?
        assert_equal Time.zone.parse(timestamp), @grade.exported_at
    end

    test "export defaults to the current time when no timestamp is given" do
        sign_in(@admin)

        post :export, params: { final_grade_name: "final", grade_ids: [ @grade.id ] }, format: :xlsx

        assert_response :success
        @grade.reload
        assert @grade.exported?
        assert_in_delta Time.current, @grade.exported_at, 5.seconds
    end

    test "export only affects the grades that were checked" do
        other_student = User.create!(name: "Other Student", mail: "other_student@example.com",
            role: :student, student_number: "87654321", status: :active, schedule: @schedule)
        other_submit = other_student.submits.create!(pset: @pset)
        other_grade = other_submit.create_grade!(grader: @admin)
        other_grade.update!(status: :published, grade: -1)

        sign_in(@admin)
        post :export, params: { final_grade_name: "final", grade_ids: [ @grade.id ] }, format: :xlsx

        assert_response :success
        assert @grade.reload.exported?
        assert other_grade.reload.published?, "an unchecked grade must stay pending"
    end

    test "is refused for non-admins" do
        sign_in(@student)
        get :index

        assert_response :forbidden
    end

    test "undo_export reverts a grade to pending" do
        @grade.update!(status: :exported, exported_at: Time.current)

        sign_in(@admin)
        patch :undo_export, params: { grade_id: @grade.id }

        assert_redirected_to admin_final_grade_path("final")
        @grade.reload
        assert @grade.published?
        assert_nil @grade.exported_at
    end

    test "undo_export is refused for non-admins" do
        @grade.update!(status: :exported, exported_at: Time.current)

        sign_in(@student)
        patch :undo_export, params: { grade_id: @grade.id }

        assert_response :forbidden
        assert @grade.reload.exported?
    end

end
