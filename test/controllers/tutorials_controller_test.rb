require "test_helper"

class TutorialsControllerTest < ActionController::TestCase

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

end
