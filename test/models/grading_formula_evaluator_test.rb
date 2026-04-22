require "test_helper"

class GradingFormulaEvaluatorTest < ActiveSupport::TestCase

  def ev(formula, vars = {})
    GradingFormulaEvaluator.evaluate(formula, vars)
  end

  # Basic arithmetic

  test "addition" do
    assert_equal 5.0, ev("2 + 3")
  end

  test "subtraction" do
    assert_equal 1.0, ev("3 - 2")
  end

  test "multiplication" do
    assert_equal 6.0, ev("2 * 3")
  end

  test "division" do
    assert_equal 1.5, ev("3 / 2.0")
  end

  test "operator precedence: * before +" do
    assert_equal 14.0, ev("2 + 3 * 4")
  end

  test "parentheses override precedence" do
    assert_equal 20.0, ev("(2 + 3) * 4")
  end

  # Variables

  test "variable lookup by symbol key" do
    assert_equal 4.0, ev("points", points: 4)
  end

  test "variable lookup by string key" do
    assert_equal 4.0, ev("points", "points" => 4)
  end

  test "variable in arithmetic" do
    assert_equal 7.0, ev("deel_1 + deel_2", deel_1: 3, deel_2: 4)
  end

  # Unary minus

  test "unary minus on number" do
    assert_equal(-5.0, ev("-(5.0)"))
  end

  test "unary minus on variable" do
    assert_equal(-3.0, ev("-x", x: 3))
  end

  # .floor and .ceil

  test "floor on literal" do
    assert_equal 7.0, ev("(7.7).floor")
  end

  test "ceil on literal" do
    assert_equal 8.0, ev("(7.1).ceil")
  end

  test "floor on variable expression" do
    assert_equal 7.0, ev("(correctness_score * 10).floor", correctness_score: 0.75)
  end

  # .round is a no-op in the parser; evaluate always applies round(1) to the result

  test "round with precision arg is no-op in parser" do
    assert_equal 7.8, ev("(7.777).round(1)")
  end

  test "round without args is no-op in parser" do
    assert_equal 7.8, ev("(7.777).round")
  end

  # Comparison and logical operators

  test "comparison returns truthy/falsy value" do
    assert_equal 1.0, ev("(1 > 0) && 1 || 0")
    assert_equal 0.0, ev("(1 > 2) && 1 || 0")
  end

  test "conditional: (points >= 9) && points || 0" do
    assert_equal 10.0, ev("(points >= 9) && points || 0", points: 10)
    assert_equal  9.0, ev("(points >= 9) && points || 0", points: 9)
    assert_equal  0.0, ev("(points >= 9) && points || 0", points: 5)
  end

  # Grading formula patterns from actual YAML files

  test "automatic grade: -(correctness_score.floor) when all checks pass" do
    assert_equal(-1.0, ev("-(correctness_score.floor)", correctness_score: 1.0))
  end

  test "automatic grade: -(correctness_score.floor) when no checks pass" do
    assert_equal 0.0, ev("-(correctness_score.floor)", correctness_score: 0.0)
  end

  test "automatic grade: (correctness_score * 10).floor" do
    assert_equal 7.0, ev("(correctness_score * 10).floor", correctness_score: 0.75)
    assert_equal 10.0, ev("(correctness_score * 10).floor", correctness_score: 1.0)
  end

  test "manual grade: (points / 6.0 * 9 + 1).round(1)" do
    assert_equal 7.0, ev("(points / 6.0 * 9 + 1).round(1)", points: 4)
    assert_equal 5.5, ev("(points / 6.0 * 9 + 1).round(1)", points: 3)
    assert_equal 10.0, ev("(points / 6.0 * 9 + 1).round(1)", points: 6)
  end

  test "multi-variable weighted formula" do
    # correctness=5, code_quality=5 on [0..5] scale -> perfect 10
    assert_equal 10.0, ev(
      "1.0 + 9.0 * (3.0 * correctness + 2.0 * code_quality - 5.0) / 20.0",
      correctness: 5, code_quality: 5
    )
    # minimum possible (both zero) -> negative grade
    assert_equal(-1.3, ev(
      "1.0 + 9.0 * (3.0 * correctness + 2.0 * code_quality - 5.0) / 20.0",
      correctness: 0, code_quality: 0
    ))
  end

  test "passthrough: done" do
    assert_equal(-1.0, ev("done", done: -1))
    assert_equal  0.0, ev("done", done: 0)
  end

  # Result is always a Float rounded to 1 decimal

  test "result is a Float" do
    assert_instance_of Float, ev("2 + 3")
  end

  test "result is rounded to 1 decimal" do
    assert_equal 1.3, ev("1.0 / 3.0 + 1.0")
  end

  # Error cases

  test "nil variable returns nil" do
    assert_nil ev("correctness_score", correctness_score: nil)
  end

  test "unknown variable returns nil" do
    assert_nil ev("unknown_var")
  end

  test "syntax error returns nil" do
    assert_nil ev("(((")
  end

  test "unexpected method name causes tokenizer error -> nil" do
    assert_nil ev("5.system")
  end

  test "nil formula returns nil" do
    assert_nil ev(nil)
  end

  test "blank formula returns nil" do
    assert_nil ev("")
  end

  test "formula with more than 10 opening parens returns nil" do
    assert_nil ev("((((((((((( 1 + 1 )))))))))))")
  end

  test "formula with exactly 10 opening parens is accepted" do
    assert_equal 1.0, ev("(((((((((( 1 ))))))))))")
  end

end
