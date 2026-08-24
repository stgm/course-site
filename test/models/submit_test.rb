require "test_helper"

class SubmitTest < ActiveSupport::TestCase

    def setup
        Settings.registration_phase = "during"
        Settings.webdav_base = "https://example.com/webdav"
        Settings.webdav_user = "user"
        Settings.webdav_pass = "pass"
        Settings.archive_course_folder = "archive"

        @schedule = Schedule.create!(name: "Submit Test Schedule", slug: "submit-test-schedule")
        @user = User.create!(name: "Submit Test User", mail: "submit_test_user@example.com",
                            schedule: @schedule, student_number: "1234567")
        @prereq = Pset.create!(name: "prereq", order: 1)
        @gated = Pset.create!(name: "gated", order: 2)
        Settings.grading = {
            "mod" => { "submits" => [ "gated" ], "requirement" => "prereq" }
        }
        @submit = Submit.new(user: @user, pset: @gated)
    end

    def publish_prereq_grade(grade)
        prereq_submit = Submit.create!(user: @user, pset: @prereq)
        Grade.create!(submit: prereq_submit, grader: @user, grade: grade, status: :published)
    end

    test "unmet_requirements is empty for a pset with no requirement" do
        other = Pset.create!(name: "unrelated", order: 3)
        submit = Submit.new(user: @user, pset: other)
        assert_empty submit.unmet_requirements
    end

    test "unmet_requirements lists the prerequisite when it hasn't been submitted at all" do
        assert_equal [ "prereq" ], @submit.unmet_requirements
    end

    test "unmet_requirements lists the prerequisite when its grade is insufficient" do
        publish_prereq_grade(4.0)
        assert_equal [ "prereq" ], @submit.unmet_requirements
    end

    test "unmet_requirements lists the prerequisite when its grade is not yet published" do
        prereq_submit = Submit.create!(user: @user, pset: @prereq)
        Grade.create!(submit: prereq_submit, grader: @user, grade: 9.0, status: :unfinished)
        assert_equal [ "prereq" ], @submit.unmet_requirements
    end

    test "unmet_requirements is empty once the prerequisite is published as sufficient" do
        publish_prereq_grade(9.0)
        assert_empty @submit.unmet_requirements
    end

    test "unmet_requirements is empty for a published pass sentinel grade" do
        publish_prereq_grade(-1)
        assert_empty @submit.unmet_requirements
    end

    test "unmet_requirements fails closed for a requirement name with no matching pset" do
        Settings.grading = { "mod" => { "submits" => [ "gated" ], "requirement" => "no_such_pset" } }
        assert_equal [ "no_such_pset" ], @submit.unmet_requirements
    end

    test "allow_new_submit? is false when a requirement is unmet, regardless of other checks" do
        assert @user.can_submit?, "test setup should make the user submittable"
        assert Submit.available?, "test setup should make submissions available"

        assert_not @submit.allow_new_submit?
    end

    test "allow_new_submit? no longer blocks on requirements once they are met" do
        publish_prereq_grade(9.0)

        assert @submit.allow_new_submit?
    end

end
