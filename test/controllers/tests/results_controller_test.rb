require "test_helper"

# The grade entry grid at /tests/:test_id/results. #calculate previews what a
# row would come out as while it is being typed, so the thing worth pinning down
# is that it agrees with what #update actually stores.
#
class Tests::ResultsControllerTest < ActionController::TestCase

    tests Tests::ResultsController

    setup do
        Settings.grading = YAML.load_file("test/models/grading/config1.yml", aliases: true)

        @schedule = Schedule.create!(name: "Test schedule")
        @group = Group.create!(name: "Test group", schedule: @schedule)

        @head = users(:test_user)
        @head.update!(role: :head, schedule: @schedule)
        @head.groups << @group

        @student = users(:test_user_2)
        # the group has to be set after the schedule: User::Groupable resets the
        # group whenever the schedule changes
        @student.update!(role: :student, schedule: @schedule)
        @student.update!(group: @group)

        # m2 is the `manual` template: one integer subgrade, float grade,
        # calculation `(points / 6.0 * 9 + 1).round(1)`
        @pset = psets(:m2)
    end

    teardown do
        Settings.grading = {}
    end

    def sign_in(user)
        session[:user_id] = user.id
        session[:user_mail] = user.mail
    end

    # Replaces m2's whole grading entry. Wholesale, because a deep merge would
    # keep the subgrades of the template it is built from.
    def grade_m2_with(entry)
        config = YAML.load_file("test/models/grading/config1.yml", aliases: true)
        config["grades"]["m2"] = entry
        Settings.grading = config
    end

    test "show renders the grid for the accessible students" do
        sign_in @head
        get :show, params: { test_id: @pset.id }

        assert_response :success
        assert_match @student.name, response.body
        assert_match "grades[#{@student.id}][subgrades][points]", response.body
    end

    test "show is closed to students" do
        sign_in @student
        get :show, params: { test_id: @pset.id }

        assert_response :forbidden
    end

    test "calculate previews the grade for a set of subgrades" do
        sign_in @head
        get :calculate, params: {
            test_id: @pset.id, user_id: @student.id, subgrades: { points: "4" }
        }

        assert_response :success
        result = JSON.parse(response.body)
        assert_equal 7.0, result["grade"]
        assert_equal "7.0", result["display"]
        assert_nil result["aggregate"]
    end

    test "calculate returns a null grade when nothing has been filled in" do
        sign_in @head
        get :calculate, params: {
            test_id: @pset.id, user_id: @student.id, subgrades: { points: "" }
        }

        assert_response :success
        assert_nil JSON.parse(response.body)["grade"]
    end

    test "calculate agrees with what update stores, decimal comma included" do
        grade_m2_with("type" => "float", "subgrades" => { "points" => "float" },
                      "calculation" => "points")

        sign_in @head
        get :calculate, params: {
            test_id: @pset.id, user_id: @student.id, subgrades: { points: "4,5" }
        }
        previewed = JSON.parse(response.body)["grade"]

        patch :update, params: {
            test_id: @pset.id,
            grades: { @student.id.to_s => { subgrades: { points: "4,5" }, notes: "" } }
        }

        stored = Submit.find_by(user: @student, pset: @pset).grade
        assert_equal 4.5, previewed
        assert_equal previewed, stored.calculated_grade
    end

    test "calculate refuses a student this grader cannot reach" do
        outsider = User.create!(name: "Outsider Person", mail: "outsider@example.com", role: :student)

        sign_in @head
        get :calculate, params: {
            test_id: @pset.id, user_id: outsider.id, subgrades: { points: "4" }
        }

        assert_response :forbidden
    end

    test "calculate reports the aggregate when the formula uses one" do
        grade_m2_with(
            "type" => "float",
            "subgrades" => { "a" => "integer", "b" => "integer", "c" => "integer" },
            "calculation" => "(sum_all / 6.0 * 9 + 1).round(1)"
        )

        sign_in @head
        get :calculate, params: {
            test_id: @pset.id, user_id: @student.id, subgrades: { a: "1", b: "2", c: "1" }
        }

        assert_response :success
        result = JSON.parse(response.body)
        assert_equal 4.0, result["aggregate"]
        assert_equal 7.0, result["grade"]
    end

    test "a whole aggregate is rendered without a decimal point" do
        grade_m2_with(
            "type" => "float",
            "subgrades" => { "a" => "integer", "b" => "integer" },
            "calculation" => "(sum_all / 48 * 9 + 1).round(1)"
        )
        submit = Submit.create!(user: @student, pset: @pset)
        submit.create_grade!(grader: @head, subgrades: { "a" => "10", "b" => "14" })

        sign_in @head
        get :show, params: { test_id: @pset.id }

        assert_match 'value="24"', response.body
        assert_no_match(/value="24\.0"/, response.body)
    end

    test "sum_all leaves both columns blank until the row is complete" do
        grade_m2_with(
            "type" => "float",
            "subgrades" => { "a" => "integer", "b" => "integer", "c" => "integer" },
            "calculation" => "(sum_all / 6.0 * 9 + 1).round(1)"
        )

        sign_in @head
        get :calculate, params: {
            test_id: @pset.id, user_id: @student.id, subgrades: { a: "1", b: "2", c: "" }
        }

        assert_response :success
        result = JSON.parse(response.body)
        assert_nil result["grade"]
        assert_nil result["aggregate"]
    end

    test "count_all keeps counting passes while the row is still incomplete" do
        grade_m2_with(
            "type" => "pass",
            "subgrades" => { "a" => "pass", "b" => "pass", "c" => "pass" },
            "calculation" => "(count_all >= 2) && -1 || 0"
        )

        sign_in @head
        get :calculate, params: {
            test_id: @pset.id, user_id: @student.id, subgrades: { a: "-1", b: "-1", c: "" }
        }

        assert_response :success
        result = JSON.parse(response.body)
        assert_equal 2.0, result["aggregate"]
        assert_equal(-1, result["grade"])
        assert_equal "v", result["display"]
    end

    test "update saves the subgrades and finishes the grade" do
        sign_in @head
        patch :update, params: {
            test_id: @pset.id,
            grades: { @student.id.to_s => { subgrades: { points: "6" }, notes: "well done" } }
        }

        assert_redirected_to test_results_path(test_id: @pset.id)
        grade = Submit.find_by(user: @student, pset: @pset).grade
        assert_equal 10.0, grade.calculated_grade
        assert_equal "well done", grade.notes
        assert grade.finished?
    end

    test "saving reports back beside the button, not in a banner over the grid" do
        sign_in @head
        patch :update, params: {
            test_id: @pset.id,
            grades: { @student.id.to_s => { subgrades: { points: "6" }, notes: "" } }
        }

        assert_equal "Saved", flash[:saved]
        assert_nil flash[:notice], "a :notice would be rendered above the grid by the layout"
    end

    test "update keeps the internal notes and the published feedback apart" do
        sign_in @head
        patch :update, params: {
            test_id: @pset.id,
            grades: { @student.id.to_s => {
                subgrades: { points: "4" },
                notes: "kept between graders",
                comments: "shown to the student"
            } }
        }

        grade = Submit.find_by(user: @student, pset: @pset).grade
        assert_equal "kept between graders", grade.notes
        assert_equal "shown to the student", grade.comments
    end

    test "show renders a feedback column after the notes column" do
        sign_in @head
        get :show, params: { test_id: @pset.id }

        assert_match "grades[#{@student.id}][comments]", response.body
        notes = response.body.index("grades[#{@student.id}][notes]")
        feedback = response.body.index("grades[#{@student.id}][comments]")
        assert notes < feedback, "feedback should come after notes"
    end

    test "update skips students this grader cannot reach" do
        outsider = User.create!(name: "Other Outsider", mail: "outsider2@example.com", role: :student)

        sign_in @head
        patch :update, params: {
            test_id: @pset.id,
            grades: { outsider.id.to_s => { subgrades: { points: "6" }, notes: "" } }
        }

        assert_nil Submit.find_by(user: outsider, pset: @pset)
    end

end
