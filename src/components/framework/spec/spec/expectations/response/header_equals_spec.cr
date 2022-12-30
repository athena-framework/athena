require "../../../spec_helper"

struct HeaderEqualsExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    ATH::Spec::Expectations::Response::HeaderEquals.new("date", "now").match(new_response headers: HTTP::Headers{"date" => "now"}).should be_true
  end

  def test_match_invalid : Nil
    ATH::Spec::Expectations::Response::HeaderEquals.new("foobar", "bizbaz").match(new_response).should be_false
    ATH::Spec::Expectations::Response::HeaderEquals.new("date", "now").match(new_response headers: HTTP::Headers{"date" => "yesterdar"}).should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Response::HeaderEquals.new("date", "now")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has header 'date' with value 'now'."
  end

  def test_negative_failure_message : Nil
    ATH::Spec::Expectations::Response::HeaderEquals.new("date", "now")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have header 'date' with value 'now'."
  end
end
