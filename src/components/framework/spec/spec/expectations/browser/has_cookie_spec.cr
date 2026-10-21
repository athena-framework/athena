require "../../../spec_helper"

private def browser_with_cookies(*cookies) : ATH::Spec::AbstractBrowser
  ATH::Spec::HTTPBrowser.new.tap do |browser|
    cookies.each { |cookie| browser.cookie_jar.set cookie }
  end
end

struct BrowserHasCookieExpectationTest < ASPEC::TestCase
  def test_match_valid : Nil
    ATH::Spec::Expectations::Browser::HasCookie.new("foo").match(browser_with_cookies ::HTTP::Cookie.new("foo", "bar")).should be_true
  end

  def test_match_valid_custom_path_and_domain : Nil
    browser = browser_with_cookies ::HTTP::Cookie.new("foo", "bar", path: "/path", domain: "example.com")

    ATH::Spec::Expectations::Browser::HasCookie.new("foo", path: "/path", domain: "example.com").match(browser).should be_true
  end

  def test_match_invalid : Nil
    ATH::Spec::Expectations::Browser::HasCookie.new("foo").match(browser_with_cookies).should be_false
  end

  def test_match_invalid_diff_path_and_domain : Nil
    browser = browser_with_cookies ::HTTP::Cookie.new("foo", "bar", path: "/path", domain: "example.com")

    ATH::Spec::Expectations::Browser::HasCookie.new("foo").match(browser).should be_false
    ATH::Spec::Expectations::Browser::HasCookie.new("foo", path: "/path", domain: "example.net").match(browser).should be_false
  end

  def test_match_non_browser : Nil
    ATH::Spec::Expectations::Browser::HasCookie.new("foo").match(nil).should be_false
  end

  def test_failure_message : Nil
    ATH::Spec::Expectations::Browser::HasCookie.new("foo")
      .failure_message(browser_with_cookies)
      .should eq "Failed asserting that the browser has cookie 'foo'."
  end

  def test_failure_message_with_path_domain_and_description : Nil
    ATH::Spec::Expectations::Browser::HasCookie.new("foo", path: "/path", domain: "example.com", description: "Some description")
      .failure_message(browser_with_cookies)
      .should eq "Some description\n\nFailed asserting that the browser has cookie 'foo' with path '/path' for domain 'example.com'."
  end

  def test_negative_failure_message : Nil
    ATH::Spec::Expectations::Browser::HasCookie.new("foo")
      .negative_failure_message(browser_with_cookies)
      .should eq "Failed asserting that the browser does not have cookie 'foo'."
  end

  def test_negative_failure_message_with_path_and_domain : Nil
    ATH::Spec::Expectations::Browser::HasCookie.new("foo", path: "/path", domain: "example.com")
      .negative_failure_message(browser_with_cookies)
      .should eq "Failed asserting that the browser does not have cookie 'foo' with path '/path' for domain 'example.com'."
  end
end
