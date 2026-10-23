require "test_helper"

class TutorialsControllerTest < ActionController::TestCase

    include ActiveJob::TestHelper

    tests TutorialsController

    setup do
        @student = users(:test_user)
        @student.update!(role: :student, student_number: "12345678", status: :active)
        @teacher = users(:test_user_2)
        @teacher.update!(role: :head)

        @practice = Exam.create!(pset: psets(:mario), locked: true, kind: :practice, config: {})
        @real = Exam.create!(pset: psets(:goldbach), locked: false, config: {})
        @tutorial = Tutorial.create!(exam: @practice, owner: @teacher, open: true)

        Settings.registration_phase = "during"
    end

    teardown do
        Settings.registration_phase = "before"
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end

    test "a student cannot create a tutorial" do
        sign_in(@student)
        assert_no_difference "Tutorial.count" do
            post :create, params: { exam_id: @practice.id }
        end
        assert_response :forbidden
    end

    test "a teacher creates a tutorial for a practice exam" do
        sign_in(@teacher)
        assert_difference "Tutorial.count", 1 do
            post :create, params: { exam_id: @practice.id }
        end
        assert_redirected_to tutorials_path
    end

    test "a teacher cannot create a tutorial for a real exam" do
        sign_in(@teacher)
        assert_no_difference "Tutorial.count" do
            assert_raises(ActiveRecord::RecordNotFound) do
                post :create, params: { exam_id: @real.id }
            end
        end
    end

    test "the teacher sees the PIN" do
        sign_in(@teacher)
        get :index
        assert_response :success
        assert_match @tutorial.pin, response.body
    end

    test "a student starts with an empty list" do
        sign_in(@student)
        get :index
        assert_response :success
        refute_match @practice.name.humanize, response.body
    end

    test "a student claims a tutorial with its PIN" do
        sign_in(@student)
        assert_difference "TutorialMembership.count", 1 do
            post :claim, params: { pin: @tutorial.pin }
        end
        get :index
        assert_match @practice.name.humanize, response.body
    end

    test "a wrong PIN claims nothing" do
        sign_in(@student)
        assert_no_difference "TutorialMembership.count" do
            post :claim, params: { pin: "x#{@tutorial.pin}" }
        end
        assert_redirected_to tutorials_path
    end

    test "a closed tutorial cannot be claimed but keeps its members" do
        TutorialMembership.create!(tutorial: @tutorial, user: @student)
        @tutorial.update!(open: false)

        other = User.create!(name: "Sam Derde", mail: "test3@example.com", role: :student,
                             student_number: "87654321", status: :active)
        sign_in(other)
        assert_no_difference "TutorialMembership.count" do
            post :claim, params: { pin: @tutorial.pin }
        end

        assert @practice.reload.open_for_user?(@student)
    end

    test "only the owner or an admin can open and close a tutorial" do
        other = User.create!(name: "Head Two", mail: "head2@example.com", role: :head)
        sign_in(other)
        patch :update, params: { id: @tutorial.id, tutorial: { open: "0" } }
        assert_response :forbidden
        assert @tutorial.reload.open?

        sign_in(@teacher)
        patch :update, params: { id: @tutorial.id, tutorial: { open: "0" } }
        assert_response :success
        assert_not @tutorial.reload.open?
    end

    test "exam mode redirects to the exams page" do
        Settings.registration_phase = "exam"
        sign_in(@student)
        get :index
        assert_redirected_to exams_path
    end

    test "a member can start a locked practice exam" do
        TutorialMembership.create!(tutorial: @tutorial, user: @student)
        @request = ActionController::TestRequest.create(ExamsController)
        @controller = ExamsController.new
        sign_in(@student)
        post :create, params: { id: @practice.id }
        assert_response :redirect
        assert_match AppConfig.exam_base_url, response.location
        assert Submit.exists?(pset: @practice.pset, user: @student)
    end

    # --- same-schedule claims -------------------------------------------------

    test "a student cannot claim a code made for another schedule" do
        mine = Schedule.create!(name: "Mine")
        other = Schedule.create!(name: "Other")
        @tutorial.update!(schedule: other)
        @student.update!(schedule: mine)

        sign_in(@student)
        assert_no_difference "TutorialMembership.count" do
            post :claim, params: { pin: @tutorial.pin }
        end
        assert_redirected_to tutorials_path
        assert_equal I18n.t("tutorial.wrong_schedule"), flash[:alert]
    end

    test "a student from the same schedule can claim, and keeps access after changing schedule" do
        mine = Schedule.create!(name: "Mine")
        @tutorial.update!(schedule: mine)
        @student.update!(schedule: mine)

        sign_in(@student)
        assert_difference "TutorialMembership.count", 1 do
            post :claim, params: { pin: @tutorial.pin }
        end

        @student.update!(schedule: Schedule.create!(name: "Elsewhere"))
        assert @practice.reload.open_for_user?(@student)
    end

    test "a code without a schedule can be claimed by anyone" do
        @tutorial.update!(schedule: nil)
        sign_in(@student)
        assert_difference "TutorialMembership.count", 1 do
            post :claim, params: { pin: @tutorial.pin }
        end
    end

    test "a new code takes the schedule the teacher has selected" do
        schedule = Schedule.create!(name: "Mine")
        @teacher.update!(schedule: schedule)
        sign_in(@teacher)
        post :create, params: { exam_id: @practice.id }
        assert_equal schedule.id, Tutorial.order(:id).last.schedule_id
    end

    # --- participant page -----------------------------------------------------

    def join(user = @student)
        TutorialMembership.create!(tutorial: @tutorial, user: user)
    end

    def with_attendance_subgrade
        Settings.grading = { "grades" => { @practice.name => {
            "subgrades" => { "notes" => "integer", "meegedaan" => "boolean" }, "calculation" => "meegedaan"
        } } }
    end

    test "the owner and an admin may open the participant list, another head may not" do
        join
        sign_in(@teacher)
        get :show, params: { id: @tutorial.id }
        assert_response :success
        assert_match @student.name, response.body

        admin = User.create!(name: "Ada Admin", mail: "ada@example.com", role: :admin)
        sign_in(admin)
        get :show, params: { id: @tutorial.id }
        assert_response :success

        other = User.create!(name: "Head Two", mail: "head2@example.com", role: :head)
        sign_in(other)
        get :show, params: { id: @tutorial.id }
        assert_response :forbidden
    end

    test "a student cannot open the participant list" do
        sign_in(@student)
        get :show, params: { id: @tutorial.id }
        assert_response :forbidden
    end

    test "the participant list shows how many checks passed" do
        join
        submits(:points_one).update!(check_results: { "summary" => { "total_check_count" => 5, "passed_check_count" => 3 } })
        sign_in(@teacher)
        get :show, params: { id: @tutorial.id }
        assert_match I18n.t("tutorial.checks", passed: 3, total: 5), response.body
    end

    test "check summary covers passed, running and unchecked" do
        submit = submits(:points_one)
        submit.update!(check_results: { "summary" => { "total_check_count" => 5, "passed_check_count" => 3 } }, check_token: nil)
        assert_equal I18n.t("tutorial.checks", passed: 3, total: 5), @tutorial.check_summary(submit)

        submit.update!(check_token: "abc")
        assert_equal :running, @tutorial.check_summary(submit)

        submit.update!(check_results: nil, check_token: nil)
        assert_nil @tutorial.check_summary(submit)
        assert_nil @tutorial.check_summary(nil)

        submit.update!(check_results: { "error" => [ "boom" ] })
        assert_nil @tutorial.check_summary(submit)
    end

    # --- attendance switch ----------------------------------------------------

    test "the attendance switch sets and clears the first boolean subgrade" do
        with_attendance_subgrade
        join
        sign_in(@teacher)

        patch :participation, params: { id: @tutorial.id, user_id: @student.id, checked: "1" }
        assert_response :success
        grade = Submit.find_by(user: @student, pset: @practice.pset).grade
        assert_equal(-1, grade.subgrades.to_h[:meegedaan])
        assert_equal @teacher, grade.grader

        patch :participation, params: { id: @tutorial.id, user_id: @student.id, checked: "0" }
        assert_equal 0, grade.reload.subgrades.to_h[:meegedaan]
    end

    test "the attendance switch needs a boolean subgrade" do
        Settings.grading = { "grades" => { @practice.name => { "subgrades" => { "notes" => "integer" } } } }
        join
        sign_in(@teacher)
        patch :participation, params: { id: @tutorial.id, user_id: @student.id, checked: "1" }
        assert_response :unprocessable_entity
    end

    test "the attendance switch only works for participants" do
        with_attendance_subgrade
        sign_in(@teacher)
        assert_raises(ActiveRecord::RecordNotFound) do
            patch :participation, params: { id: @tutorial.id, user_id: @student.id, checked: "1" }
        end
    end

    # --- checks ---------------------------------------------------------------

    test "run checks enqueues a job for one participant or for all" do
        join
        @practice.pset.update!(config: { "type" => "practice", "check" => { "tool" => "x" } })
        sign_in(@teacher) # @student already has a submit for this pset in the fixtures

        assert_enqueued_with(job: SubmitCheckJob) do
            post :recheck, params: { id: @tutorial.id, user_id: @student.id }
        end
        assert_redirected_to tutorial_path(@tutorial)

        assert_enqueued_jobs 1, only: SubmitCheckJob do
            post :recheck, params: { id: @tutorial.id }
        end
    end

end
