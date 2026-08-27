require "test_helper"

class OverviewsControllerTest < ActionController::TestCase

    tests OverviewsController

    setup do
        @schedule = Schedule.create!(name: "Empty schedule")

        @admin = users(:test_user)
        @admin.update!(role: :admin, schedule: @schedule)
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end

    test "renders an empty table when the schedule has no students" do
        sign_in(@admin)
        get :show, params: { id: @schedule.slug, status: "active" }

        assert_response :success
        assert_match "grade-table", response.body
    end

end
