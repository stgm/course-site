require "test_helper"

# The zip downloads build their archive in a temp file and hand it to send_file, after
# registering it with Rack::TempfileReaper so it is unlinked once the response has been
# sent. The unlinking is Rack's job; registering the file is ours, so that is what is
# asserted here alongside the contents of the download.
#
class DownloadsControllerTest < ActionController::TestCase

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end

    def entries_of(body)
        Tempfile.create([ "downloaded", ".zip" ], binmode: true) do |file|
            file.write(body)
            file.rewind
            Zip::File.open(file.path) { |zip| zip.to_h { |e| [ e.name, e.get_input_stream.read ] } }
        end
    end

    def registered_tempfiles
        @controller.request.env["rack.tempfiles"] || []
    end


    class SubmissionDownloadTest < DownloadsControllerTest
        tests SubmissionsController

        setup do
            @user = users(:test_user)
            @submit = submits(:one)
            @submit.update!(user: @user, submitted_at: Time.current)
            @submit.files.attach(io: StringIO.new("print(1)"), filename: "a.py", content_type: "text/plain")
            @submit.files.attach(io: StringIO.new("print(2)"), filename: "b.py", content_type: "text/plain")
        end

        test "sends a zip of all the files" do
            sign_in(@user)
            get :download, params: { submission_id: @submit.id }

            assert_response :success
            assert_equal "application/zip", response.media_type
            assert_equal({ "a.py" => "print(1)", "b.py" => "print(2)" }, entries_of(response.body))
        end

        test "registers the archive for cleanup" do
            sign_in(@user)
            get :download, params: { submission_id: @submit.id }

            assert_equal 1, registered_tempfiles.size,
                "the archive must be handed to Rack::TempfileReaper or it leaks on disk"
        end

        test "disambiguates files submitted under the same name" do
            @submit.files.attach(io: StringIO.new("print(3)"), filename: "a.py", content_type: "text/plain")

            sign_in(@user)
            get :download, params: { submission_id: @submit.id }

            assert_equal [ "a (2).py", "a.py", "b.py" ], entries_of(response.body).keys.sort
        end
    end


    class CourseArchiveDownloadTest < DownloadsControllerTest
        tests Admin::CourseController

        setup do
            @admin = users(:test_user)
            @admin.update!(role: :admin)
        end

        test "sends the course archive as a zip" do
            sign_in(@admin)
            get :archive

            assert_response :success
            assert_equal "application/zip", response.media_type
            assert_includes entries_of(response.body).keys, "grades.xlsx"
        end

        test "registers the archive for cleanup" do
            sign_in(@admin)
            get :archive

            assert_equal 1, registered_tempfiles.size,
                "the archive must be handed to Rack::TempfileReaper or it leaks on disk"
        end

        test "is refused for non-admins" do
            @admin.update!(role: :student)
            sign_in(@admin)
            get :archive

            assert_response :forbidden
        end
    end

end
