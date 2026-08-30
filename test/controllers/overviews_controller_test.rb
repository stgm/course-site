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

    test "renders generated submits and grades in the overview" do
        Settings.grading = {
            "grades" => {
                "hello" => { "type" => "pass", "calculation" => "done",
                             "subgrades" => { "done" => "boolean" } },
                "wave"  => { "type" => "float", "calculation" => "(points / 6.0 * 9 + 1).round(1)",
                             "subgrades" => { "points" => "integer" } }
            },
            "week_1" => { "show_progress" => true,
                          "submits" => { "hello" => 1, "wave" => 1 } }
        }

        schedule = Schedule.create!(name: "Filled schedule")
        group = schedule.groups.create!(name: "Group A")
        hello = Pset.create!(name: "hello")
        wave  = Pset.create!(name: "wave")

        student = User.create!(mail: "s1@example.test", name: "Sam Student",
                               role: :student, schedule: schedule, status: :active)
        student.update!(group: group)

        Current.user = @admin
        pass = student.submits.create!(pset: hello, submitted_at: 2.days.ago).create_grade
        pass.update!(subgrades: { "done" => -1 }, grader: @admin, status: :published)

        num = student.submits.create!(pset: wave, submitted_at: 1.day.ago).create_grade
        num.update!(subgrades: { "points" => 5 }, grader: @admin, status: :published)

        sign_in(@admin)
        get :show, params: { id: schedule.slug, status: "active" }

        assert_response :success
        assert_match "Sam Student", response.body
        assert_match "8.5", response.body                    # wave: (5 / 6.0 * 9 + 1).round(1)
        # modules are separated by an alternating background band
        assert_no_match %r{border-left: 1px solid gray}, response.body
        # module header carries the clipping wrapper and the full (un-truncated) label
        assert_match %r{<span class="module-header">Week 1</span>}, response.body
    ensure
        Settings.grading = {}
    end

end
