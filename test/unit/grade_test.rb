require "test_helper"

class GradeTest < ActiveSupport::TestCase

  # Grade::Calculator#calculate_grade
  # Stubs grading_config and subgrades to avoid submit/schedule fixture dependencies.

  def grade_with(formula:, subgrades:)
    grade = Grade.new
    config = { "calculation" => formula }
    sg     = OpenStruct.new(subgrades)
    grade.define_singleton_method(:grading_config) { config }
    grade.define_singleton_method(:subgrades)      { sg }
    yield grade
  end

  test "calculate_grade for manual grade: (points / 6.0 * 9 + 1).round(1)" do
    grade_with(formula: "(points / 6.0 * 9 + 1).round(1)", subgrades: { points: 4 }) do |g|
      assert_equal 7.0, g.calculate_grade
    end
  end

  test "calculate_grade for manual grade with full points" do
    grade_with(formula: "(points / 6.0 * 9 + 1).round(1)", subgrades: { points: 6 }) do |g|
      assert_equal 10.0, g.calculate_grade
    end
  end

  test "calculate_grade for exam grade: cijfer passthrough" do
    grade_with(formula: "cijfer", subgrades: { cijfer: 8.5 }) do |g|
      assert_equal 8.5, g.calculate_grade
    end
  end

  test "calculate_grade for automatic grade: done passthrough" do
    grade_with(formula: "done", subgrades: { done: -1 }) do |g|
      assert_equal(-1.0, g.calculate_grade)
    end
  end

  test "calculate_grade returns nil when subgrades missing required variable" do
    grade_with(formula: "points", subgrades: {}) do |g|
      assert_nil g.calculate_grade
    end
  end

  test "calculate_grade: sum of subgrades" do
    grade_with(formula: "deel_1 + deel_2", subgrades: { deel_1: 3, deel_2: 4 }) do |g|
      assert_equal 7.0, g.calculate_grade
    end
  end

end
