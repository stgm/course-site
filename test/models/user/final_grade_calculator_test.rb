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

end
