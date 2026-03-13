require "./spec_helper"

struct BundleAuthorizationTest < ASPEC::TestCase
  def test_set_cookie : Nil
    token_factory = AMC::Spec::AssertingTokenFactory.new(
      "JWT",
      ["foo"],
      ["bar"],
      {"x-foo" => "baz"},
    )

    authorization = ABM::Authorization.new new_hub_registry(token_factory: token_factory)
    request = new_request(headers: ::HTTP::Headers{"host" => "example.com"})

    authorization.set_cookie request, ["foo"], ["bar"], {"x-foo" => "baz"}
    token_factory.called?.should be_true

    cookies = request.attributes.get?("_mercure_authorization_cookies", Hash(String, ::HTTP::Cookie)).should_not be_nil
    cookies[""].value.should_not be_empty
  end

  def test_set_cookie_stores_in_request_attributes : Nil
    authorization = ABM::Authorization.new new_hub_registry
    request = new_request(headers: ::HTTP::Headers{"host" => "example.com"})

    authorization.set_cookie request

    cookies = request.attributes.get?("_mercure_authorization_cookies", Hash(String, ::HTTP::Cookie)).should_not be_nil
    cookies.size.should eq 1
  end

  def test_set_cookie_prevents_duplicate : Nil
    authorization = ABM::Authorization.new new_hub_registry
    request = new_request(headers: ::HTTP::Headers{"host" => "example.com"})

    expect_raises AMC::Exception::Runtime, "The 'mercureAuthorization' cookie for the 'default hub' has already been set." do
      authorization.set_cookie request
      authorization.set_cookie request
    end
  end

  def test_clear_cookie : Nil
    authorization = ABM::Authorization.new new_hub_registry
    request = new_request(headers: ::HTTP::Headers{"host" => "example.com"})

    authorization.clear_cookie request

    cookies = request.attributes.get?("_mercure_authorization_cookies", Hash(String, ::HTTP::Cookie)).should_not be_nil
    cookies[""].value.should be_empty
  end

  def test_create_cookie : Nil
    authorization = ABM::Authorization.new new_hub_registry
    request = new_request(headers: ::HTTP::Headers{"host" => "example.com"})

    cookie = authorization.create_cookie request
    cookie.name.should eq "mercureAuthorization"
    cookie.value.should_not be_empty
  end
end
