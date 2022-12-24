require "../../../spec_helper"

struct CookieValueEqualsExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar"

    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar").match(response).should be_true
  end

  def test_match_valid_custom_path : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", path: "/path"

    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/path").match(response).should be_true
  end

  def test_match_valid_custom_domain : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", domain: "example.com"

    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", domain: "example.com").match(response).should be_true
  end

  def test_match_valid_custom_path_and_domain : Nil
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", path: "/path", domain: "example.com"

    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/path", domain: "example.com").match(response).should be_true
  end

  def test_match_invalid : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar").match(new_response).should be_false
  end

  def test_match_invalid_diff_path
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", path: "/path"

    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar").match(response).should be_false
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/").match(response).should be_false
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/bar").match(response).should be_false
  end

  def test_match_invalid_diff_domain
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", domain: "example.com"

    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar").match(response).should be_false
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", domain: "foo.example.com").match(response).should be_false
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", domain: "example.net").match(response).should be_false
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", domain: "domain.com").match(response).should be_false
  end

  def test_match_invalid_diff_domain_and_path
    response = new_response
    response.cookies << HTTP::Cookie.new "foo", "bar", path: "/path", domain: "example.com"

    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar").match(response).should be_false
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/bar", domain: "example.com").match(response).should be_false
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/path", domain: "domain.com").match(response).should be_false
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/bar", domain: "domain.com").match(response).should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has cookie 'foo' with value 'bar'."
  end

  def test_failure_message_with_path : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/path")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has cookie 'foo' with path '/path' with value 'bar'."
  end

  def test_failure_message_with_domain : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", domain: "example.com")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has cookie 'foo' for domain 'example.com' with value 'bar'."
  end

  def test_failure_message_with_path_and_domain : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/path", domain: "example.com")
      .failure_message(new_response)
      .should contain "Failed asserting that the response has cookie 'foo' with path '/path' for domain 'example.com' with value 'bar'."
  end

  def test_negative_failure_message : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have cookie 'foo' with value 'bar'."
  end

  def test_failure_message_with_path : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/path")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have cookie 'foo' with path '/path' with value 'bar'."
  end

  def test_failure_message_with_domain : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", domain: "example.com")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have cookie 'foo' for domain 'example.com' with value 'bar'."
  end

  def test_failure_message_with_path_and_domain : Nil
    ATH::Spec::Expectations::Response::CookieValueEquals.new("foo", "bar", path: "/path", domain: "example.com")
      .negative_failure_message(new_response)
      .should contain "Failed asserting that the response does not have cookie 'foo' with path '/path' for domain 'example.com' with value 'bar'."
  end
end
