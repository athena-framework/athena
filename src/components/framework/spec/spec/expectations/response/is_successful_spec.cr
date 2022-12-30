require "../../../spec_helper"

struct IsSuccessfulExpectationTest < ASPEC::TestCase
  def initialize
    @target = ATH::Spec::Expectations::Response::IsSuccessful.new
  end

  def test_match_valid : Nil
    @target.match(new_response).should be_true
  end

  def test_match_invalid : Nil
    @target.match(new_response status: :im_a_teapot).should be_false
  end

  def test_failure_message : Nil
    @target.failure_message(new_response status: :not_found).should contain "Failed asserting that the response is successful:\nHTTP/1.1 404 Not Found"
  end

  def test_negative_failure_message : Nil
    @target.negative_failure_message(new_response).should contain "Failed asserting that the response is not successful:\nHTTP/1.1 200 OK"
  end
end
