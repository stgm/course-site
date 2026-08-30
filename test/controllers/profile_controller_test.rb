require "test_helper"

class ProfileControllerTest < ActionController::TestCase

    tests ProfileController

    setup do
        @schedule = Schedule.create!(name: "Empty schedule")
        @user = users(:test_user)
        @user.update!(schedule: @schedule)
        session[:user_id] = @user.id
        session[:user_mail] = @user.mail
    end

    test "stores collapsed modules per schedule" do
        post :collapsed_modules, params: { schedule: @schedule.slug, modules: [ "week 1", "week 2" ] }

        assert_response :success
        assert_equal [ "week 1", "week 2" ], @user.reload.collapsed_modules(@schedule)
    end

    test "an empty list clears the collapsed modules" do
        @user.collapse_modules(@schedule, [ "week 1" ])

        post :collapsed_modules, params: { schedule: @schedule.slug }

        assert_response :success
        assert_equal [], @user.reload.collapsed_modules(@schedule)
    end

end
