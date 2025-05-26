require "test_helper"

class ExamsControllerTest < ActionController::TestCase

    def setup
        @user = User.create!(mail: "student@example.com")
        @admin = User.create!(mail: "admin@example.com", role: :admin)
        
        Current.user = @admin
        Settings.registration_phase = "during"

        @pset = Pset.create!(name: "pset1")
        @exam = Exam.create!(pset: @pset, config: {
            "name" => "hoi",
            "files" => [], "hidden_files" => [], "buttons" => []
        })

        @submit = Submit.create!(user: @user, pset: @pset, exam_code: "abc123", submitted_at: nil)
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end
  
    test "should get index for student with only unlocked exams" do
        @exam.update(locked: false)
        locked_exam = Exam.create!(name: "Locked", pset: @pset, locked: true)

        sign_in(@user)
        get exams_url

        assert_response :success
        assert_match @exam.name, response.body
        refute_match "Locked", response.body
    end

    test "should get all exams for admin" do
        @exam.update(locked: true)

        sign_in(@admin)
        get exams_url

        assert_response :success
        assert_match @exam.name, response.body
    end
  
    test "should create submit and redirect to external editor" do
        sign_in(@user)

        post exam_url(@exam), as: :post

        @submit.reload
        assert @submit.exam_code.present?
        assert_response :redirect
        assert_match Settings.exam_base_url, response.headers["Location"]
    end
  
    test "should return exam config JSON if code and IP match" do
        @user.update(last_known_ip: "1.2.3.4")
        @submit.update(exam_code: "abc123")
        @exam.update(locked: false)

        get json_exam_url(id: @exam.id, code: "abc123"), headers: { "REMOTE_ADDR" => "1.2.3.4" }

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal Course.short_name, body["course_name"]
        assert_nil body["locked"]
    end

    test "should fail json with wrong code" do
        get json_exam_url(id: @exam.id, code: "wrong")

        assert_response :bad_request
        assert_match "invalid", response.body
    end

    test "should fail json with wrong IP during exam" do
        Settings.registration_phase = "exam"

        @user.update(last_known_ip: "1.2.3.4")
        get json_exam_url(id: @exam.id, code: "abc123"), headers: { "REMOTE_ADDR" => "5.6.7.8" }

        assert_response :precondition_failed
        assert_match "wrong ip", response.body

        Settings.registration_phase = "during"
    end
  
    test "should accept post and update files" do
        @exam.update(locked: false)
        files_param = { "main.py" => { name: "main.py", content: "print(1)" } }

        post post_exam_url(id: @exam.id, code: "abc123"), params: { files: files_param }

        assert_response :accepted
        assert_match "OK", response.body
        @submit.reload
        assert_not_nil @submit.submitted_at
    end

    test "should reject post if locked" do
        @submit.update(locked: true)

        post post_exam_url(id: @exam.id, code: "abc123")

        assert_response :locked
        assert_match "locked", response.body
    end
  
end
