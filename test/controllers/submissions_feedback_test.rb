require "test_helper"

class SubmissionsFeedbackTest < ActionController::TestCase

    tests SubmissionsController

    setup do
        @student = users(:test_user)
        schedule = Schedule.create!(name: "Feedback Test Schedule", slug: "feedback-test-schedule")
        @student.update!(role: :student, status: :active, schedule: schedule)
        @pset = psets(:mario)
        @submit = Submit.create!(user: @student, pset: @pset,
                                 check_results: { "runs" => [ { "name" => "x", "checks" => [ { "description" => "check one", "passed" => true } ] } ] })
        Settings.registration_phase = "during"
        session[:user_id] = @student.id
        session[:user_mail] = @student.mail
    end

    teardown { Settings.registration_phase = "before" }

    test "feedback is shown in a normal phase" do
        get :feedback, params: { submission_id: @submit.id }
        assert_response :success
        assert_includes response.body, "check one"
    end

    test "feedback is not shown in exam mode" do
        Settings.registration_phase = "exam"
        assert_raises(ActionController::RoutingError) do
            get :feedback, params: { submission_id: @submit.id }
        end
    end

    test "feedback of an unpublished declared exam is not shown" do
        Exam.create!(pset: @pset, kind: "exam", config: {})
        assert_raises(ActionController::RoutingError) do
            get :feedback, params: { submission_id: @submit.id }
        end
    end

    test "feedback of a published declared exam is shown" do
        Exam.create!(pset: @pset, kind: "exam", config: {})
        Grade.create!(submit: @submit, grader: @student, grade: 7, status: :published)
        get :feedback, params: { submission_id: @submit.id }
        assert_response :success
    end

    test "the overview has no check results button for hidden results" do
        Settings.registration_phase = "exam"
        get :index
        assert_response :success
        assert_no_match(%r{/submissions/#{@submit.id}/feedback}, response.body)
    end

    test "the overview has a check results button for visible results" do
        get :index
        assert_response :success
        assert_match(%r{/submissions/#{@submit.id}/feedback}, response.body)
    end

end
