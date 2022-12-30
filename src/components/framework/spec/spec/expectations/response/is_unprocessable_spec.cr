require "../../../spec_helper"

struct IsUnprocessableExpectationTest < ASPEC::TestCase
  def initialize
    @target = ATH::Spec::Expectations::Response::IsUnprocessable.new
  end

  def test_match_valid : Nil
    @target.match(new_response status: :unprocessable_entity).should be_true
  end

  def test_match_invalid : Nil
    @target.match(new_response).should be_false
  end

  def test_failure_message : Nil
    @target.failure_message(new_response status: :not_found).should contain "Failed asserting that the response is unprocessable:\nHTTP/1.1 404 Not Found"
  end

  def test_negative_failure_message : Nil
    @target.negative_failure_message(new_response status: :unprocessable_entity).should contain "Failed asserting that the response is not unprocessable:\nHTTP/1.1 422 Unprocessable Entity"
  end
end
