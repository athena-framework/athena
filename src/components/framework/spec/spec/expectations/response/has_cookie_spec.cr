require "../../../spec_helper"

struct HasCookieExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar"

    ATH::Spec::Expectations::Response::HasCookie.new("foo").match(response).should be_true
  end

  def test_match_valid_custom_path : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", path: "/path"

    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/path").match(response).should be_true
  end

  def test_match_valid_custom_domain : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", domain: "example.com"

    ATH::Spec::Expectations::Response::HasCookie.new("foo", domain: "example.com").match(response).should be_true
  end

  def test_match_valid_custom_path_and_domain : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", path: "/path", domain: "example.com"

    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/path", domain: "example.com").match(response).should be_true
  end

  def test_match_invalid : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo").match(new_response).should be_false
  end

  def test_match_invalid_diff_path
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", path: "/path"

    ATH::Spec::Expectations::Response::HasCookie.new("foo").match(response).should be_false
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/").match(response).should be_false
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/bar").match(response).should be_false
  end

  def test_match_invalid_diff_domain
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", domain: "example.com"

    ATH::Spec::Expectations::Response::HasCookie.new("foo").match(response).should be_false
    ATH::Spec::Expectations::Response::HasCookie.new("foo", domain: "foo.example.com").match(response).should be_false
    ATH::Spec::Expectations::Response::HasCookie.new("foo", domain: "example.net").match(response).should be_false
    ATH::Spec::Expectations::Response::HasCookie.new("foo", domain: "domain.com").match(response).should be_false
  end

  def test_match_invalid_diff_domain_and_path
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", path: "/path", domain: "example.com"

    ATH::Spec::Expectations::Response::HasCookie.new("foo").match(response).should be_false
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/bar", domain: "example.com").match(response).should be_false
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/path", domain: "domain.com").match(response).should be_false
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/bar", domain: "domain.com").match(response).should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has cookie 'foo'."
  end

  def test_failure_message_with_path : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/path")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has cookie 'foo' with path '/path'."
  end

  def test_failure_message_with_domain : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo", domain: "example.com")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has cookie 'foo' for domain 'example.com'."
  end

  def test_failure_message_with_path_and_domain : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/path", domain: "example.com")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has cookie 'foo' with path '/path' for domain 'example.com'."
  end

  def test_negative_failure_message : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have cookie 'foo'."
  end

  def test_failure_message_with_path : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/path")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have cookie 'foo' with path '/path'."
  end

  def test_failure_message_with_domain : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo", domain: "example.com")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have cookie 'foo' for domain 'example.com'."
  end

  def test_failure_message_with_path_and_domain : Nil
    ATH::Spec::Expectations::Response::HasCookie.new("foo", path: "/path", domain: "example.com")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have cookie 'foo' with path '/path' for domain 'example.com'."
  end
end
