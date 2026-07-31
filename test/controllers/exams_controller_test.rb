require "test_helper"

# The exam endpoints are split in two halves. #index and #create are ordinary logged-in
# pages; #json and #post are called by the external editor with no session at all, and are
# authenticated purely by the exam_code on the submit (plus an IP match while an exam is
# actually running). Both halves are covered here.
#
class ExamsControllerTest < ActionController::TestCase

    tests ExamsController

    setup do
        @user = users(:test_user)
        @user.update!(role: :student, student_number: "12345678", status: :active,
                      last_known_ip: "1.2.3.4")

        @admin = users(:test_user_2)
        @admin.update!(role: :admin)

        @pset = psets(:mario)
        @exam = Exam.create!(pset: @pset, locked: false, config: {
            "name" => "hoi",
            "files" => [], "hidden_files" => [], "buttons" => []
        })

        # a second exam on its own pset -- Pset has_one :exam, so it cannot share @pset
        @locked_pset = psets(:goldbach)
        @locked_exam = Exam.create!(pset: @locked_pset, locked: true, config: {})

        @submit = submits(:points_one) # test_user on the mario pset
        @submit.update!(exam_code: "abc123", submitted_at: nil, locked: false)

        Settings.registration_phase = "during"
        Settings.course = { "short_name" => "TESTCOURSE" }
    end

    teardown do
        Settings.registration_phase = "before"
        Settings.exam_current = nil
        Settings.course = {}
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end

    # controller tests only switch the request to multipart for Rack::Test::UploadedFile,
    # so that is the type the editor's file posts have to be simulated with
    def upload(filename, content)
        Rack::Test::UploadedFile.new(StringIO.new(content), "text/plain", original_filename: filename)
    end


    test "should get index for student with only unlocked exams" do
        sign_in(@user)
        get :index

        assert_response :success
        assert_match @pset.name.humanize, response.body
        refute_match @locked_pset.name.humanize, response.body
    end

    test "locked exams are not listed outside exam mode, not even for an admin" do
        sign_in(@admin)
        get :index

        assert_response :success
        assert_match @pset.name.humanize, response.body
        refute_match @locked_pset.name.humanize, response.body
    end

    test "should list only the current exam in exam mode" do
        Settings.registration_phase = "exam"
        Settings.exam_current = @locked_exam.id

        sign_in(@user)
        get :index

        assert_response :success
        assert_match @locked_pset.name.humanize, response.body
        refute_match @pset.name.humanize, response.body
    end

    test "should create submit and redirect to external editor" do
        sign_in(@user)
        post :create, params: { id: @exam.id }

        assert_response :redirect
        assert_match AppConfig.exam_base_url, response.location

        @submit.reload
        assert @submit.exam_code.present?
        # a fresh session code is minted on every start, so the old one is gone
        refute_equal "abc123", @submit.exam_code
    end

    test "should return exam config JSON if code and IP match" do
        @request.remote_addr = "1.2.3.4"
        get :json, params: { id: @exam.id, code: "abc123" }

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal "TESTCOURSE", body["course_name"]
        assert_equal post_exam_url(id: @exam.id), body["postback"]
        assert_nil body["locked"]
    end

    test "should fail json with wrong code" do
        get :json, params: { id: @exam.id, code: "wrong" }

        assert_response :bad_request
        assert_match "incorrect", response.body
    end

    test "should fail json with wrong IP during exam" do
        Settings.registration_phase = "exam"
        Settings.exam_current = @exam.id

        @request.remote_addr = "5.6.7.8"
        get :json, params: { id: @exam.id, code: "abc123" }

        assert_response :precondition_failed
        assert_match "wrong ip", response.body
    end

    test "should accept post and update files" do
        post :post, params: { id: @exam.id, code: "abc123",
                              files: { "main.py" => upload("main.py", "print(1)") } }

        assert_response :accepted
        assert_match "OK", response.body

        @submit.reload
        assert_not_nil @submit.submitted_at
        assert_equal [ "main.py" ], @submit.files.map { |f| f.filename.to_s }
    end

    test "should reject post if locked" do
        @submit.update!(locked: true)

        post :post, params: { id: @exam.id, code: "abc123" }

        assert_response :locked
        assert_match "locked", response.body
    end

end
