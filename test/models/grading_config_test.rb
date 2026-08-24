require "test_helper"

class GradingConfigTest < ActiveSupport::TestCase

    def config_for(grading)
        Settings.grading = grading
        GradingConfig.base
    end

    test "a list of assignments becomes a map of weights" do
        config = config_for({
            "checks" => { "type" => "pass_all", "submits" => [ "check_1", "check_2" ] }
        })

        assert_equal({ "check_1" => 1, "check_2" => 1 }, config.components["checks"]["submits"])
    end

    test "a list of bonus assignments becomes a map of weights" do
        config = config_for({
            "cijfers" => { "submits" => { "m2" => 1 }, "bonus" => [ "goldbach" ] }
        })

        assert_equal({ "goldbach" => 1 }, config.components["cijfers"]["bonus"])
    end

    test "weighed assignments are left alone" do
        config = config_for({
            "cijfers" => { "submits" => { "m2" => 1, "m4" => 2 } }
        })

        assert_equal({ "m2" => 1, "m4" => 2 }, config.components["cijfers"]["submits"])
    end

    test "a final grade written as a list of components" do
        config = config_for({
            "checks" => { "type" => "pass_all", "submits" => [ "check_1" ] },
            "exams"  => { "type" => "pass_any", "submits" => [ "exam_1" ] },
            "calculation" => {
                "final" => { "type" => "pass", "components" => [ "checks", "exams" ] }
            }
        })

        assert_equal "pass", config.calculation["final"]["type"]
        assert_equal({ "checks" => 1, "exams" => 1 }, config.calculation["final"]["components"])
        assert_equal [ "checks", "exams" ], config.categories
    end

    test "a final grade written as weighed components without a type" do
        config = config_for({
            "punten" => { "submits" => { "m2" => 1 } },
            "calculation" => { "eindcijfer" => { "punten" => 25, "tentamen" => 75 } }
        })

        assert_equal "float", config.calculation["eindcijfer"]["type"]
        assert_equal({ "punten" => 25, "tentamen" => 75 }, config.calculation["eindcijfer"]["components"])
    end

    test "an unknown component type is reported" do
        config = config_for({
            "checks" => { "type" => "pass_some", "submits" => [ "check_1" ] }
        })

        assert_match "checks/pass_some", config.validate.join
    end

    test "a pass component in a numeric final grade is reported" do
        config = config_for({
            "checks" => { "type" => "pass_all", "submits" => [ "check_1" ] },
            "calculation" => { "eindcijfer" => { "checks" => 1 } }
        })

        errors = config.validate.join
        assert_match "eindcijfer", errors
        assert_match "pass/fail components: checks", errors
    end

    test "a pass component at weight 0 in a numeric final grade is allowed" do
        config = config_for({
            "checks" => { "type" => "pass_all", "submits" => [ "check_1" ] },
            "punten" => { "submits" => { "m2" => 1 } },
            "calculation" => { "eindcijfer" => { "checks" => 0, "punten" => 1 } }
        })

        assert_empty config.validate
    end

    test "weighed components in a pass final grade are reported" do
        config = config_for({
            "checks" => { "type" => "pass_all", "submits" => [ "check_1" ] },
            "calculation" => {
                "final" => { "type" => "pass", "components" => { "checks" => 1 } }
            }
        })

        assert_match "written as a list of names", config.validate.join
    end

    test "final grade names are collected across every schedule" do
        # the SP course keeps its root grading.yml empty and defines everything per
        # schedule, and registering grades has to cover all of them
        Settings.grading = {}
        Settings.schedule_grading = {
            "SP S1" => { "calculation" => { "sp1_resit" => { "sp1_checks" => 1 },
                                            "sp1_final" => { "sp1_checks" => 1 } } },
            "DP S1" => { "calculation" => { "dp_final" => { "dp_grades" => 1 } } }
        }

        assert_equal [ "dp_final", "sp1_final", "sp1_resit" ], GradingConfig.all_final_grade_names
    end

    test "a final grade named in the base config counts once" do
        Settings.grading = { "calculation" => { "eindcijfer" => { "punten" => 1 } } }
        Settings.schedule_grading = { "Standard" => {} }

        assert_equal [ "eindcijfer" ], GradingConfig.all_final_grade_names
    end

    test "a list of components passes validation" do
        config = config_for({
            "checks" => { "type" => "pass_all", "submits" => [ "check_1" ] },
            "calculation" => {
                "final" => { "type" => "pass", "components" => [ "checks" ] }
            }
        })

        assert_empty config.validate
    end

    test "overview skips a submit that has no matching pset" do
        Pset.create!(name: "check_1", order: 1)

        config = config_for({
            "checks" => { "show_progress" => true, "submits" => { "check_1" => 1, "check_missing" => 1 } }
        })

        name, flag, psets = config.overview.first
        assert_equal "checks", name
        assert_equal [ "check_1" ], psets.map { |pset, weight| pset.name }
    end

    test "overview skips a final grade that has no matching pset" do
        config = config_for({
            "calculation" => { "eindcijfer" => { "punten" => 1 } }
        })

        name, flag, psets = config.overview.last
        assert_equal "Final", name
        assert_empty psets
    end

    test "a schedule override merges into an existing category instead of replacing it" do
        Pset.create!(name: "check_1", order: 1)

        Settings.grading = { "checks" => { "type" => "pass_all", "submits" => { "check_1" => 1 } } }
        Settings.schedule_grading = { "S1" => { "checks" => { "show_progress" => true } } }

        config = GradingConfig.with_schedule("S1")

        assert_equal "pass_all", config.components["checks"]["type"]
        name, flag, psets = config.overview.first
        assert_equal "checks", name
        assert_equal [ "check_1" ], psets.map { |pset, weight| pset.name }
    end

    test "overview does not crash for a category with no submits key" do
        config = config_for({
            "checks" => { "show_progress" => true }
        })

        name, flag, psets = config.overview.first
        assert_equal "checks", name
        assert_empty psets
    end

    test "overview_config does not crash for a category with no submits key" do
        config = config_for({
            "checks" => { "show_progress" => true }
        })

        content = config.overview_config["checks"]
        assert_empty content["submits"]
        assert_empty content["subgrades"]
        assert_equal false, content["show_calculated"]
    end

    test "a single requirement name becomes a one-element list" do
        config = config_for({
            "arrays" => { "submits" => [ "sort" ], "requirement" => "intro" }
        })

        assert_equal [ "intro" ], config.components["arrays"]["requirement"]
    end

    test "a list of requirement names is left alone" do
        config = config_for({
            "arrays" => { "submits" => [ "sort" ], "requirement" => [ "intro", "quiz" ] }
        })

        assert_equal [ "intro", "quiz" ], config.components["arrays"]["requirement"]
    end

    test "required_submits_for returns the requirement of the component the pset belongs to" do
        config = config_for({
            "arrays" => { "submits" => [ "sort" ], "requirement" => "intro" },
            "other" => { "submits" => [ "unrelated" ] }
        })

        assert_equal [ "intro" ], config.required_submits_for("sort")
        assert_empty config.required_submits_for("unrelated")
    end

    test "required_submits_for is empty for a pset that isn't in any component" do
        config = config_for({
            "arrays" => { "submits" => [ "sort" ], "requirement" => "intro" }
        })

        assert_empty config.required_submits_for("nowhere")
    end

    test "validate flags a requirement naming a grade that doesn't exist" do
        config = config_for({
            "grades" => { "sort" => {}, "intro" => {} },
            "arrays" => { "submits" => [ "sort" ], "requirement" => "typo_intro" }
        })

        assert_match "Requirements arrays/typo_intro", config.validate.join
    end

    test "validate accepts a requirement naming an existing grade" do
        config = config_for({
            "grades" => { "sort" => {}, "intro" => {} },
            "arrays" => { "submits" => [ "sort" ], "requirement" => "intro" }
        })

        assert_empty config.validate
    end

end
