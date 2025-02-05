require "../../../spec_helper"

struct FormatEqualsExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request, "json").match(new_response headers: HTTP::Headers{"content-type" => "application/json"}).should be_true
  end

  def test_match_valid_no_format : Nil
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request).match(new_response headers: HTTP::Headers{"content-type" => ""}).should be_true
  end

  def test_match_invalid : Nil
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request).match(new_response).should be_false
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request, "json").match(new_response).should be_false
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request, "json").match(new_response headers: HTTP::Headers{"content-type" => "text/html"}).should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request, "json")
      .failure_message(new_response)
      .should contain "Failed asserting that the response format is 'json':\nHTTP/1.1 200"
  end

  def test_failure_message_no_format : Nil
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request)
      .failure_message(new_response)
      .should contain "Failed asserting that the response format is 'null':\nHTTP/1.1 200"
  end

  def test_negative_failure_message : Nil
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request, "json")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response format is not 'json':\nHTTP/1.1 200"
  end

  def test_negative_failure_message_no_format : Nil
    ATH::Spec::Expectations::Response::FormatEquals.new(new_request)
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response format is not 'null':\nHTTP/1.1 200"
  end
end
