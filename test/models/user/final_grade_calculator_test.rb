require "test_helper"

class User::FinalGradeCalculatorTest < ActiveSupport::TestCase

    def setup
        Settings.grading = YAML.load_file('test/models/grading/config1.yml', aliases: true)
    end

    test "grade" do
        grading_config = User.first.grading_config
        @calculator = User::FinalGradeCalculator.new(grading_config)

        assert_equal 7, @calculator.run(User.first.all_submits)['berekening_op_gemiddelde']
        assert_equal 8, @calculator.run(User.first.all_submits)['eindcijfer']
        assert_equal 8.5, @calculator.run(User.first.all_submits)['berekening_op_punten']

        grading_config = User.first.grading_config
        @calculator = User::FinalGradeCalculator.new(grading_config)

        assert_equal 9, @calculator.run(User.second.all_submits)['eindcijfer']
    end

    # the pass/fail strategies only ever read #assigned_grade off the grades they are
    # given, so they can be exercised without any submit or grade records
    FakeGrade = Struct.new(:assigned_grade)

    PASS_CONFIG = {
        "checks" => { "type" => "pass_all", "submits" => [ "check_1", "check_2" ] },
        "exams"  => { "type" => "pass_any", "submits" => [ "exam_1", "exam_2" ] },
        "calculation" => {
            "final" => { "type" => "pass", "components" => [ "checks", "exams" ] }
        }
    }.freeze

    def pass_grade(grades)
        Settings.grading = PASS_CONFIG.deep_dup
        submits = grades.transform_values { |grade| FakeGrade.new(grade) }
        User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["final"]
    end

    test "pass_all and pass_any together make a pass" do
        assert_equal(-1, pass_grade("check_1" => -1, "check_2" => -1, "exam_2" => -1))
    end

    test "a numeric grade of 5.5 and up counts as a pass" do
        assert_equal(-1, pass_grade("check_1" => -1, "check_2" => 7.0, "exam_2" => 5.5))
    end

    test "pass_any fails once an assignment is graded and none is passed" do
        assert_equal :insufficient, pass_grade("check_1" => -1, "check_2" => -1, "exam_1" => 0)
    end

    test "pass_any waits while nothing has been graded" do
        assert_equal :not_attempted, pass_grade("check_1" => -1, "check_2" => -1)
    end

    test "pass_all fails on a failed assignment, even before the exams" do
        assert_equal :insufficient, pass_grade("check_1" => -1, "check_2" => 0)
    end

    test "pass_all fails on an insufficient numeric grade" do
        assert_equal :insufficient, pass_grade("check_1" => -1, "check_2" => 5.4, "exam_1" => -1)
    end

    test "pass_all waits for an ungraded assignment" do
        assert_equal :not_attempted, pass_grade("check_1" => -1, "exam_1" => -1)
    end

    test "a resubmit exception is not a grade and fails nothing" do
        assert_equal :not_attempted, pass_grade("check_1" => -1, "check_2" => -2, "exam_1" => -1)
        assert_equal :not_attempted, pass_grade("check_1" => -1, "check_2" => -1, "exam_1" => -2)
    end

    test "a pass final grade is a fail when a component reports a number" do
        # a numeric component inside a pass/fail final grade cannot be a pass, however
        # high it is: only the pass sentinel counts
        Settings.grading = {
            "average" => { "submits" => { "m2" => 1 } },
            "calculation" => { "final" => { "type" => "pass", "components" => [ "average" ] } }
        }
        submits = { "m2" => FakeGrade.new(9.0) }
        assert_equal :insufficient, User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["final"]
    end

end
