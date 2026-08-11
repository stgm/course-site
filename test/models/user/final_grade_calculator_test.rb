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
    # given, plus #updated_at for the note on a resit, so they can be exercised without
    # any submit or grade records
    FakeGrade = Struct.new(:assigned_grade, :updated_at)

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

    test "a component with nothing to report keeps a failed one from being registered" do
        # check_2 failed, but the exams have nothing to say yet: a final grade that is not
        # registered at all outranks a failing one
        assert_equal :not_attempted, pass_grade("check_1" => -1, "check_2" => 0)
    end

    test "pass_all fails on a failed assignment" do
        Settings.grading = {
            "checks" => { "type" => "pass_all", "submits" => [ "check_1", "check_2" ] },
            "calculation" => { "final" => { "type" => "pass", "components" => [ "checks" ] } }
        }
        submits = { "check_1" => FakeGrade.new(-1), "check_2" => FakeGrade.new(0) }
        assert_equal :insufficient, User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["final"]
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

    # Two registrations off the same list of exam attempts: the first attempt a student made
    # decides sp1_final, every later one decides sp1_resit.
    ATTEMPT_CONFIG = {
        "checks"      => { "type" => "pass_all", "submits" => [ "check_1" ] },
        "exams"       => { "type" => "pass_first", "submits" => [ "exam_1", "exam_2", "exam_3" ] },
        "exams_resit" => { "type" => "pass_last", "submits" => [ "exam_1", "exam_2", "exam_3" ] },
        "calculation" => {
            "sp1_final" => { "type" => "pass", "components" => [ "checks", "exams" ] },
            "sp1_resit" => { "type" => "pass", "components" => [ "checks", "exams_resit" ] }
        }
    }.freeze

    # the pair of registrations, [ sp1_final, sp1_resit ]
    def registrations(grades, dates = {})
        Settings.grading = ATTEMPT_CONFIG.deep_dup
        submits = grades.to_h do |name, grade|
            [ name, FakeGrade.new(grade, dates.fetch(name, Time.current)) ]
        end
        @result = User::FinalGradeCalculator.new(GradingConfig.base).run(submits)
        [ @result["sp1_final"], @result["sp1_resit"] ]
    end

    test "one attempt made is the first registration and no resit" do
        assert_equal [ -1, :not_attempted ], registrations("check_1" => -1, "exam_1" => -1)
    end

    test "a failed first attempt fails the first registration only" do
        assert_equal [ :insufficient, :not_attempted ], registrations("check_1" => -1, "exam_1" => 0)
    end

    test "a passed second attempt is a resit, and the first registration stays a fail" do
        assert_equal [ :insufficient, -1 ],
            registrations("check_1" => -1, "exam_1" => 0, "exam_2" => -1)
    end

    test "two failed attempts fail both registrations" do
        assert_equal [ :insufficient, :insufficient ],
            registrations("check_1" => -1, "exam_1" => 0, "exam_2" => 0)
    end

    test "a third attempt takes over the resit from the second" do
        assert_equal [ :insufficient, -1 ],
            registrations("check_1" => -1, "exam_1" => 0, "exam_2" => 0, "exam_3" => -1)
    end

    test "a failed check with an attempt made fails the first registration" do
        assert_equal [ :insufficient, :not_attempted ], registrations("check_1" => 0, "exam_1" => -1)
    end

    test "a failed check without any attempt registers nothing" do
        assert_equal [ :not_attempted, :not_attempted ], registrations("check_1" => 0)
    end

    test "an unfinished check registers nothing, however the exam went" do
        assert_equal [ :not_attempted, :not_attempted ], registrations("exam_1" => -1)
    end

    test "nothing made registers nothing" do
        assert_equal [ :not_attempted, :not_attempted ], registrations("check_1" => -1)
    end

    test "the first attempt is the first one listed, not the first one graded" do
        # exam_2 was graded a month before exam_1, and exam_1 is still the first attempt
        result = registrations({ "check_1" => -1, "exam_1" => 0, "exam_2" => -1 },
            { "exam_1" => Time.current, "exam_2" => 1.month.ago })
        assert_equal [ :insufficient, -1 ], result
    end

    test "a resubmit exception is not an attempt" do
        # only exam_2 counts, so it is the first attempt and there is no resit
        assert_equal [ -1, :not_attempted ],
            registrations("check_1" => -1, "exam_1" => -2, "exam_2" => -1)
    end

    test "the resit records which attempt it overwrote" do
        registrations({ "check_1" => -1, "exam_1" => 0, "exam_2" => 0, "exam_3" => -1 },
            { "exam_2" => Date.new(2025, 12, 15).noon })

        notes = @result["_debug"]["sp1_resit"].join("\n")
        assert_match "sp1_resit is now based on exam_3 (sufficient", notes
        assert_match "previous result from exam_2 (insufficient, graded 15 December 2025)", notes

        # the first registration came out of a single attempt, so it overwrote nothing
        assert_no_match(/overwritten/, @result["_debug"]["sp1_final"].join("\n"))
    end

end
