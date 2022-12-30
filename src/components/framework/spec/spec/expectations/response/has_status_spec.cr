require "../../../spec_helper"

struct HasStatusExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    ATH::Spec::Expectations::Response::HasStatus.new(:ok).match(new_response).should be_true
    ATH::Spec::Expectations::Response::HasStatus.new(200).match(new_response).should be_true
  end

  def test_match_invalid : Nil
    ATH::Spec::Expectations::Response::HasStatus.new(:ok).match(new_response status: :not_found).should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Response::HasStatus.new(:not_found)
      .failure_message(new_response)
      .should contain "Failed asserting that the response status is 'NOT_FOUND':\nHTTP/1.1 200 OK"
  end

  def test_negative_failure_message : Nil
    ATH::Spec::Expectations::Response::HasStatus.new(:ok)
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response status is not 'OK':\nHTTP/1.1 200 OK"
  end
end
