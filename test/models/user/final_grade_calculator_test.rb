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

    # a weight-0 pass/fail component inside a weighted final grade: a mandatory sign-off
    # that earns no points and does not move the average, but can still block the result
    WEIGHTED_WITH_PASS_CONFIG = {
        "average" => { "submits" => { "m2" => 1 } },
        "signoff" => { "type" => "pass_all", "submits" => [ "check_1" ] },
        "calculation" => {
            "final" => { "average" => 1, "signoff" => 0 }
        }
    }.freeze

    def weighted_pass_grade(grades)
        Settings.grading = WEIGHTED_WITH_PASS_CONFIG.deep_dup
        submits = grades.transform_values { |grade| FakeGrade.new(grade) }
        User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["final"]
    end

    test "a weight-0 pass_all component that passes doesn't change the numeric final grade" do
        assert_equal 9, weighted_pass_grade("m2" => 9.0, "check_1" => -1)
    end

    test "a weight-0 pass_all component that fails forces the final grade to insufficient" do
        assert_equal :insufficient, weighted_pass_grade("m2" => 9.0, "check_1" => 0)
    end

    test "a weight-0 pass_all component that is ungraded forces not_attempted" do
        assert_equal :not_attempted, weighted_pass_grade("m2" => 9.0)
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

    test "a maximum component with a minimum fails below the threshold" do
        Settings.grading = {
            "best" => { "type" => "maximum", "submits" => [ "m1", "m2" ], "minimum" => 5.5 },
            "calculation" => { "final" => { "type" => "pass", "components" => [ "best" ] } }
        }
        submits = { "m1" => FakeGrade.new(4.0), "m2" => FakeGrade.new(5.0) }
        assert_equal :insufficient, User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["final"]
    end

    test "drop: lowest drops the lowest-scoring submit from the average" do
        Settings.grading = {
            "average" => { "submits" => { "m1" => 1, "m2" => 1, "m3" => 1 }, "drop" => "lowest" },
            "calculation" => { "final" => { "average" => 1 } }
        }
        submits = {
            "m1" => FakeGrade.new(4.0),
            "m2" => FakeGrade.new(8.0),
            "m3" => FakeGrade.new(10.0)
        }
        # m1 (the lowest) is dropped, so the average is (8 + 10) / 2 = 9, not (4 + 8 + 10) / 3
        assert_equal 9, User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["final"]
    end

    # werkcolleges count towards the final grade for the students who did them, and are
    # left out for the students who did none at all
    OPTIONAL_CONFIG = {
        "werkcolleges" => { "type" => "points", "submits" => { "wc_1" => 1, "wc_2" => 1 } },
        "tentamen" => { "type" => "points", "submits" => { "exam_1" => 9 } },
        "calculation" => {
            "eindcijfer" => { "werkcolleges?" => 6, "tentamen" => 18 }
        }
    }.freeze

    def optional_grade(grades)
        Settings.grading = OPTIONAL_CONFIG.deep_dup
        submits = grades.transform_values { |grade| FakeGrade.new(grade) }
        User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["eindcijfer"]
    end

    test "an optional component is left out when nothing in it was made" do
        # the tentamen carries the whole grade: 6 out of 9 points is a 7
        assert_equal 7, optional_grade("exam_1" => 6)
    end

    test "an optional component counts once something in it was made" do
        # one werkcollege out of two is a 5.5, weighed 6 against the tentamen's 7 at 18
        assert_equal 6.5, optional_grade("exam_1" => 6, "wc_1" => -1)
    end

    test "an optional component that was fully made counts as it always did" do
        # both werkcolleges is a 10, weighed 6 against the tentamen's 7 at 18
        assert_equal 8, optional_grade("exam_1" => 6, "wc_1" => -1, "wc_2" => -1)
    end

    test "an optional points component that earned nothing is left out too" do
        # the werkcolleges were graded, and scored no points at all, which counts as
        # nothing yielded rather than as a 1 that drags the tentamen down
        assert_equal 7, optional_grade("exam_1" => 6, "wc_1" => 0, "wc_2" => 0)
    end

    test "an optional component is kept once it earned any points at all" do
        # half the werkcolleges is a 5.5, weighed 6 against the tentamen's 7 at 18
        assert_equal 6.5, optional_grade("exam_1" => 6, "wc_1" => -1, "wc_2" => 0)
    end

    test "a minimum on an optional component fails the final grade instead of dropping it" do
        # the minimum turns "no points earned" into a result rather than an absence, so
        # there is nothing left to drop: a minimum and optional do not sit well together
        Settings.grading = OPTIONAL_CONFIG.deep_dup.tap do |config|
            config["werkcolleges"]["minimum"] = 5.5
        end
        submits = { "exam_1" => FakeGrade.new(6), "wc_1" => FakeGrade.new(0), "wc_2" => FakeGrade.new(0) }

        assert_equal :insufficient,
            User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["eindcijfer"]
    end

    test "no grade at all when every component is optional and none was made" do
        Settings.grading = {
            "werkcolleges" => { "type" => "points", "submits" => { "wc_1" => 1 } },
            "calculation" => { "eindcijfer" => { "werkcolleges?" => 6 } }
        }

        assert_equal :not_attempted,
            User::FinalGradeCalculator.new(GradingConfig.base).run({})["eindcijfer"]
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

    # A course whose skills are each assessed on more than one paper: karel on the first
    # and second tussentoets, python on the second tussentoets and the tentamen, advanced
    # python on the tentamen only. Components name the parts of a paper as "paper.part",
    # and the last attempt at a skill decides it.
    FakeTest = Struct.new(:subgrades, :assigned_grade, :updated_at)

    SUBGRADE_CONFIG = {
        "karel" => { "type" => "points_last",
            "submits" => { "tussentoets_1.karel" => 3, "tussentoets_2.karel" => 3 } },
        "python" => { "type" => "points_last",
            "submits" => { "tussentoets_2.python" => 6, "tentamen.python" => 6 } },
        "advanced_python" => { "type" => "points",
            "submits" => { "tentamen.advanced_python" => 9 } },
        "calculation" => {
            "eindcijfer" => { "karel" => 3, "python" => 6, "advanced_python" => 9 }
        }
    }.freeze

    def skill_grade(papers, dates = {})
        Settings.grading = SUBGRADE_CONFIG.deep_dup
        submits = papers.to_h do |name, subgrades|
            [ name, FakeTest.new(subgrades, nil, dates.fetch(name, Time.current)) ]
        end
        @result = User::FinalGradeCalculator.new(GradingConfig.base).run(submits)
        @result["eindcijfer"]
    end

    test "a component reads the part of a paper it names" do
        # every skill made once, at full marks, so every component is a 10
        assert_equal 10, skill_grade(
            "tussentoets_1" => { karel: 3 },
            "tussentoets_2" => { karel: nil, python: 6 },
            "tentamen" => { python: nil, advanced_python: 9 })
    end

    test "the last attempt at a skill counts, even when it is the lower one" do
        # karel was 3 out of 3 the first time and 0 the second, and the second counts:
        # karel 1, python 10, advanced python 10 weighed 3:6:9
        assert_equal 8.5, skill_grade(
            "tussentoets_1" => { karel: 3 },
            "tussentoets_2" => { karel: 0, python: 6 },
            "tentamen" => { python: nil, advanced_python: 9 })
    end

    test "an empty part is not an attempt, where a zero is" do
        # the same papers as above with karel left blank the second time: the first
        # attempt still decides it, so the final grade is a 10 rather than an 8.5
        assert_equal 10, skill_grade(
            "tussentoets_1" => { karel: 3 },
            "tussentoets_2" => { karel: nil, python: 6 },
            "tentamen" => { python: nil, advanced_python: 9 })
    end

    test "a skill retaken on a later paper is decided there" do
        # python failed at the second tussentoets and made good at the tentamen
        assert_equal 10, skill_grade(
            "tussentoets_1" => { karel: 3 },
            "tussentoets_2" => { karel: nil, python: 0 },
            "tentamen" => { python: 6, advanced_python: 9 })
    end

    test "a skill that was never attempted scores no points" do
        # karel and python were never sat: both are a 1, advanced python a 10
        assert_equal 6, skill_grade("tentamen" => { python: nil, advanced_python: 9 })
    end

    test "a resubmit exception on a paper means none of its parts was attempted" do
        Settings.grading = SUBGRADE_CONFIG.deep_dup
        submits = {
            "tussentoets_1" => FakeTest.new({ karel: 3 }, nil, Time.current),
            "tussentoets_2" => FakeTest.new({ karel: 0, python: 6 }, -2, Time.current),
            "tentamen" => FakeTest.new({ python: nil, advanced_python: 9 }, nil, Time.current)
        }
        result = User::FinalGradeCalculator.new(GradingConfig.base).run(submits)

        # the second tussentoets counts for nothing, so karel is decided by the first
        # attempt (a 10) and python was never sat at all (a 1)
        assert_equal 7, result["eindcijfer"]
    end

    test "points_last with attempt_required registers nothing until an attempt is made" do
        Settings.grading = {
            "karel" => { "type" => "points_last", "attempt_required" => true,
                "submits" => { "tussentoets_1.karel" => 3 } },
            "calculation" => { "eindcijfer" => { "karel" => 3 } }
        }
        submits = { "tussentoets_1" => FakeTest.new({ karel: nil }, nil, Time.current) }

        assert_equal :not_attempted,
            User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["eindcijfer"]
    end

    test "a pass on a part counts as full marks for that part" do
        Settings.grading = {
            "karel" => { "type" => "points_last", "submits" => { "tussentoets_1.karel" => 3 } },
            "calculation" => { "eindcijfer" => { "karel" => 3 } }
        }
        submits = { "tussentoets_1" => FakeTest.new({ karel: -1 }, nil, Time.current) }

        assert_equal 10,
            User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["eindcijfer"]
    end

    # the same course with its subjects marked as exam material, so that no grade is
    # registered at all until the student has sat some part of the exam
    EXPECTED_ATTEMPT_CONFIG = SUBGRADE_CONFIG.deep_dup.tap do |config|
        %w[ karel python advanced_python ].each { |name| config[name]["exam"] = true }
    end.freeze

    def guarded_grade(papers)
        Settings.grading = EXPECTED_ATTEMPT_CONFIG.deep_dup
        submits = papers.to_h { |name, subgrades| [ name, FakeTest.new(subgrades, nil, Time.current) ] }
        User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["eindcijfer"]
    end

    test "a final grade is not registered when no part of the exam was sat" do
        assert_equal :not_attempted, guarded_grade({})
    end

    test "one part of the exam sat is enough to register a final grade" do
        # karel alone, and the subjects that were never sat count as zero points
        assert_equal 2.5, guarded_grade("tussentoets_1" => { karel: 3 })
    end

    test "a zero counts as having sat a part" do
        assert_equal 1, guarded_grade("tussentoets_1" => { karel: 0 })
    end

    test "an empty part is not something sat" do
        assert_equal :not_attempted, guarded_grade("tussentoets_1" => { karel: nil })
    end

    test "a final grade with no exam components is not held back" do
        # the same papers, but nothing is marked as exam material
        assert_equal 1, skill_grade("tussentoets_1" => { karel: nil })
    end

    test "a component that is not an exam does not count as sitting something" do
        Settings.grading = EXPECTED_ATTEMPT_CONFIG.deep_dup.tap do |config|
            config["werkcolleges"] = { "type" => "points", "submits" => { "wc_1" => 1 } }
            config["calculation"] = { "eindcijfer" =>
                { "werkcolleges" => 6, "karel" => 3, "python" => 6, "advanced_python" => 9 } }
        end
        submits = { "wc_1" => FakeGrade.new(-1) }

        assert_equal :not_attempted,
            User::FinalGradeCalculator.new(GradingConfig.base).run(submits)["eindcijfer"]
    end

    test "the whole exam sat registers as usual" do
        assert_equal 10, guarded_grade(
            "tussentoets_1" => { karel: 3 },
            "tussentoets_2" => { karel: nil, python: 6 },
            "tentamen" => { python: nil, advanced_python: 9 })
    end

    test "every attempt-based component records the attempt it skipped over" do
        skill_grade({
            "tussentoets_1" => { karel: 3 },
            "tussentoets_2" => { karel: 1, python: 6 },
            "tentamen" => { python: 3, advanced_python: 9 }
        }, {
            "tussentoets_1" => Date.new(2025, 11, 4).noon,
            "tussentoets_2" => Date.new(2025, 12, 16).noon
        })

        notes = @result["_debug"]["eindcijfer"].join("\n")
        assert_match "eindcijfer is now based on tussentoets_2.karel (1", notes
        assert_match "previous result from tussentoets_1.karel (3, graded 4 November 2025)", notes
        assert_match "eindcijfer is now based on tentamen.python (3", notes
        assert_match "previous result from tussentoets_2.python (6, graded 16 December 2025)", notes
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
