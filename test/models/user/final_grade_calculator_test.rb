require "test_helper"

class User::FinalGradeCalculatorTest < ActiveSupport::TestCase

    def setup
        Settings.grading = YAML.load_file('test/models/grading/config1.yml', aliases: true)
    end

    test "grade" do
        assert_equal 8, User::FinalGradeCalculator.run_for(User.first.all_submits)['eindcijfer']
        assert_equal 8.5, User::FinalGradeCalculator.run_for(User.second.all_submits)['eindcijfer']
        assert_equal 8.5, User::FinalGradeCalculator.run_for(User.first.all_submits)['berekening_op_punten']
    end

end
