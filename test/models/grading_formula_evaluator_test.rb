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

  # sum_all and count_all

  test "sum_all adds every variable" do
    assert_equal 9.0, ev("sum_all", a: 2, b: 3, c: 4)
  end

  test "sum_all with string keys" do
    assert_equal 9.0, ev("sum_all", "a" => 2, "b" => 3, "c" => 4)
  end

  test "sum_all is nil when a variable has no value" do
    assert_nil ev("sum_all", a: 2, b: nil, c: 4)
  end

  test "sum_all inside a larger expression" do
    assert_equal 7.0, ev("(sum_all / 6.0 * 9 + 1).round(1)", a: 1, b: 3)
  end

  test "count_all counts passes" do
    assert_equal 2.0, ev("count_all", a: -1, b: 0, c: -1)
  end

  test "count_all counts filled variables only, without failing on blanks" do
    assert_equal 1.0, ev("count_all", a: -1, b: nil, c: 0)
  end

  test "count_all is zero when nothing has passed" do
    assert_equal 0.0, ev("count_all", a: 0, b: 0)
  end

  test "count_all inside a larger expression" do
    assert_equal(-1.0, ev("(count_all >= 2) && -1 || 0", a: -1, b: -1, c: nil))
    assert_equal  0.0, ev("(count_all >= 2) && -1 || 0", a: -1, b: 0, c: nil)
  end

  test "aggregate_keys limits which variables the aggregates range over" do
    vars = { a: 2, b: 3, leftover: 100 }
    assert_equal 5.0, GradingFormulaEvaluator.evaluate("sum_all", vars, aggregate_keys: [ :a, :b ])
  end

  test "aggregate_keys naming a variable that has no value makes sum_all nil" do
    assert_nil GradingFormulaEvaluator.evaluate("sum_all", { a: 2 }, aggregate_keys: [ :a, :b ])
  end

  test "aggregates coexist with plain variables in one formula" do
    assert_equal 7.0, GradingFormulaEvaluator.evaluate(
      "sum_all + bonus", { a: 2, b: 3, bonus: 2 }, aggregate_keys: [ :a, :b ]
    )
  end

  test "an unscoped aggregate ranges over every variable, bonus included" do
    assert_equal 9.0, ev("sum_all + bonus", a: 2, b: 3, bonus: 2)
  end

  test "aggregate_function reports which aggregate a formula uses" do
    assert_equal :sum_all, GradingFormulaEvaluator.aggregate_function("(sum_all / 6.0).round(1)")
    assert_equal :count_all, GradingFormulaEvaluator.aggregate_function("count_all >= 3 && -1 || 0")
    assert_nil GradingFormulaEvaluator.aggregate_function("(points / 6.0 * 9 + 1).round(1)")
    assert_nil GradingFormulaEvaluator.aggregate_function(nil)
  end

  test "aggregate_function is not fooled by a longer name containing one" do
    assert_nil GradingFormulaEvaluator.aggregate_function("my_sum_all_total")
  end

  # Aggregates divide as floats, never as integers

  test "sum_all divides as a float" do
    # integer division would collapse 24 / 48 to 0 and give 1.0
    assert_equal 5.5, ev("sum_all / 48 * 9 + 1", a: 10, b: 14)
  end

  test "count_all divides as a float" do
    assert_equal 0.7, ev("count_all / 3", a: -1, b: -1, c: 0)
  end

  test "an aggregate divided by an aggregate stays a float" do
    assert_equal 1.0, ev("count_all / count_all", a: -1, b: -1)
    assert_equal 1.0, ev("sum_all / sum_all", a: 3, b: 4)
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
