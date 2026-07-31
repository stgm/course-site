require "test_helper"

# Role changes happen inside the modal, where the application layout's flash never
# gets rendered. The modal layout renders it instead, so these check both that the
# messages are set and that they actually reach the screen.
#
class AdminUsersControllerTest < ActionController::TestCase

    tests Admin::UsersController

    setup do
        # the modal's tab strip reads the current schedule's grading config
        @schedule = Schedule.create!(name: "Test schedule")

        @admin = users(:test_user)
        @admin.update!(role: :admin, schedule: @schedule)

        @student = users(:test_user_2)
        @student.update!(role: :student, schedule: @schedule)
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end


    test "reports a role change" do
        sign_in(@admin)
        patch :set_role, params: { user_id: @student.id, user: { role: :assistant } }

        assert_redirected_to user_path(@student)
        assert_equal "Test User2 is now assistant.", flash[:notice]
        assert @student.reload.assistant?
    end

    test "reports that the last admin keeps the role" do
        sign_in(@admin)
        patch :set_role, params: { user_id: @admin.id, user: { role: :student } }

        assert_redirected_to user_path(@admin)
        assert_equal "Role cannot be taken away from the last admin", flash[:alert]
        assert_nil flash[:notice]
        assert @admin.reload.admin?
    end

    test "renders the flash inside the modal" do
        sign_in(@admin)
        patch :set_role, params: { user_id: @admin.id, user: { role: :student } }
        get :index

        assert_response :success
        assert_match "Role cannot be taken away from the last admin", response.body
        assert_match "alert-danger", response.body
    end

end
