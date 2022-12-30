require "../../../spec_helper"

struct HasHeaderExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    ATH::Spec::Expectations::Response::HasHeader.new("date").match(new_response headers: HTTP::Headers{"date" => "now"}).should be_true
  end

  def test_match_invalid : Nil
    ATH::Spec::Expectations::Response::HasHeader.new("foobar").match(new_response).should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Response::HasHeader.new("date")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has header 'date'."
  end

  def test_failure_message_with_description : Nil
    ATH::Spec::Expectations::Response::HasHeader.new("date", description: "Oh noes")
      .failure_message(new_response)
      .should contain "Oh noes\n\nFailed asserting that the response has header 'date'."
  end

  def test_negative_failure_message : Nil
    ATH::Spec::Expectations::Response::HasHeader.new("date")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have header 'date'."
  end

  def test_negative_failure_message_with_description : Nil
    ATH::Spec::Expectations::Response::HasHeader.new("date", description: "Oh noes")
      .negative_failure_message(new_response)
      .should contain "Oh noes\n\nFailed asserting that the response does not have header 'date'."
  end
end
