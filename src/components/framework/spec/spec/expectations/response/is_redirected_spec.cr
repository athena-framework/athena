require "../../../spec_helper"

struct IsRedirectedExpectationTest < ASPEC::TestCase
  def initialize
    @target = ATH::Spec::Expectations::Response::IsRedirected.new
  end

  def test_match_valid : Nil
    @target.match(new_response status: :moved_permanently).should be_true
  end

  def test_match_invalid : Nil
    @target.match(new_response status: :im_a_teapot).should be_false
  end

  def test_failure_message : Nil
    @target.failure_message(new_response status: :not_found).should contain "Failed asserting that the response is redirected:\nHTTP/1.1 404 Not Found"
  end

  def test_negative_failure_message : Nil
    @target.negative_failure_message(new_response status: :moved_permanently).should contain "Failed asserting that the response is not redirected:\nHTTP/1.1 301 Moved Permanently"
  end
end
