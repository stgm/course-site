require "test_helper"

class Submit::AutoCheck::ScoreCalculatorTest < ActiveSupport::TestCase

  class StubSubmit
    include Submit::AutoCheck::ScoreCalculator

    attr_reader :check_results, :grading_config

    def initialize(check_results: nil, grading_config: nil)
      @check_results  = check_results
      @grading_config = grading_config
    end
  end

  def stub(passed: nil, total: nil, automatic: nil)
    check_results = if total
      { "summary" => { "total_check_count" => total, "passed_check_count" => passed } }
    end
    grading_config = automatic ? { "automatic" => automatic } : {}
    StubSubmit.new(check_results: check_results, grading_config: grading_config)
  end

  # correctness_score

  test "correctness_score is nil without check_results" do
    assert_nil stub.correctness_score
  end

  test "correctness_score is 0 when total checks is zero" do
    assert_equal 0, stub(passed: 0, total: 0).correctness_score
  end

  test "correctness_score returns ratio of passed to total" do
    assert_in_delta 0.75, stub(passed: 3, total: 4).correctness_score
    assert_in_delta 1.0,  stub(passed: 4, total: 4).correctness_score
    assert_in_delta 0.0,  stub(passed: 0, total: 4).correctness_score
  end

  # automatic_scores

  test "automatic_scores returns empty hash when no automatic config" do
    assert_equal({}, stub.automatic_scores)
  end

  test "automatic_scores evaluates -(correctness_score.floor) when all checks pass" do
    result = stub(passed: 4, total: 4, automatic: { "done" => "-(correctness_score.floor)" }).automatic_scores
    assert_equal({ "done" => -1.0 }, result)
  end

  test "automatic_scores evaluates -(correctness_score.floor) when no checks pass" do
    result = stub(passed: 0, total: 4, automatic: { "done" => "-(correctness_score.floor)" }).automatic_scores
    assert_equal({ "done" => 0.0 }, result)
  end

  test "automatic_scores returns nil for a rule when correctness_score is nil" do
    result = stub(automatic: { "done" => "-(correctness_score.floor)" }).automatic_scores
    assert_equal({ "done" => nil }, result)
  end

  test "automatic_scores evaluates (correctness_score * 10).floor" do
    result = stub(passed: 3, total: 4, automatic: { "score" => "(correctness_score * 10).floor" }).automatic_scores
    assert_equal({ "score" => 7.0 }, result)
  end

end
