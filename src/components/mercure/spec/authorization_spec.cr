require "./spec_helper"

struct AuthorizationTest < ASPEC::TestCase
  def test_jwt_lifetime : Nil
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: 4000, protocol_version: :legacy)
    ) { "ID" })

    authorization = AMC::Authorization.new registry
    cookie = authorization.create_cookie ::HTTP::Request.new("GET", "https://example.com", headers: ::HTTP::Headers{"host" => "example.com"})

    payload, _ = JWT.decode(cookie.value, verify: false, validate: false)
    payload["exp"].as_i?.should be_a Int32
  end

  def test_set_cookie_zero_expiration : Nil
    token_factory = AMC::Spec::AssertingTokenFactory.new(
      "JWT",
      [AMC::Grant.new(:subscribe, ["foo"]), AMC::Grant.new(:publish, ["bar"])],
      {"x-foo" => "baz"},
    )

    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: token_factory
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "https://example.com", headers: ::HTTP::Headers{"host" => "example.com"})
    response = ::HTTP::Server::Response.new IO::Memory.new

    authorization = AMC::Authorization.new registry, Time::Span.zero, :lax
    authorization.set_cookie request, response, [AMC::Grant.new(:subscribe, ["foo"]), AMC::Grant.new(:publish, ["bar"])], {"x-foo" => "baz"}
    token_factory.called?.should be_true

    cookie = response.cookies.first
    cookie.max_age.should eq Time::Span.zero
    cookie.value.should_not be_empty
    cookie.samesite.try &.lax?.should be_true
  end

  def test_set_cookie_default_expiration : Nil
    token_factory = AMC::Spec::AssertingTokenFactory.new(
      "JWT",
      [AMC::Grant.new(:subscribe, ["foo"]), AMC::Grant.new(:publish, ["bar"])],
      {"x-foo" => "baz"},
    )

    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: token_factory
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "https://example.com", headers: ::HTTP::Headers{"host" => "example.com"})
    response = ::HTTP::Server::Response.new IO::Memory.new

    authorization = AMC::Authorization.new registry, cookie_samesite: :lax
    authorization.set_cookie request, response, [AMC::Grant.new(:subscribe, ["foo"]), AMC::Grant.new(:publish, ["bar"])], {"x-foo" => "baz"}
    token_factory.called?.should be_true

    cookie = response.cookies.first
    cookie.name.should eq "__Secure-mercure_access_token"
    cookie.path.should eq "/.well-known/mercure"
    cookie.secure.should be_true
    cookie.max_age.should eq 1.hour
    cookie.value.should_not be_nil
    cookie.samesite.try &.lax?.should be_true
  end

  def test_clear_cookie : Nil
    token_factory = AMC::Spec::AssertingTokenFactory.new("JWT")

    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: token_factory
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "https://example.com", headers: ::HTTP::Headers{"host" => "example.com"})
    response = ::HTTP::Server::Response.new IO::Memory.new

    authorization = AMC::Authorization.new registry
    authorization.clear_cookie request, response

    cookie = response.cookies.first
    cookie.value.should be_empty
    cookie.max_age.should eq 1.second
  end

  @[DataProvider("applicable_cookie_domains")]
  def test_applicable_cookie_domains(expected : String?, hub_url : String, request_url : String) : Nil
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      hub_url,
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: 4000, protocol_version: :legacy)
    ) { "ID" })

    uri = URI.parse request_url
    request = ::HTTP::Request.new("GET", uri.path.presence ? uri.path : "/", headers: ::HTTP::Headers{"host" => uri.hostname || ""})

    authorization = AMC::Authorization.new registry

    cookie = authorization.create_cookie request
    cookie.domain.should eq expected
  end

  def applicable_cookie_domains : Tuple
    {
      {".example.com", "https://foo.bar.baz.example.com", "https://foo.bar.baz.qux.example.com"},
      {".foo.bar.baz.example.com", "https://mercure.foo.bar.baz.example.com", "https://app.foo.bar.baz.example.com"},
      {"example.com", "https://demo.example.com", "https://example.com"},
      {".example.com", "https://mercure.example.com", "https://app.example.com"},
      {".example.com", "https://example.com/.well-known/mercure", "https://app.example.com"},
      {nil, "https://example.com/.well-known/mercure", "https://example.com"},
    }
  end

  @[DataProvider("nonapplicable_cookie_domains")]
  def test_nonapplicable_cookie_domains(hub_url : String, request_url : String) : Nil
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      hub_url,
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: 4000, protocol_version: :legacy)
    ) { "ID" })

    uri = URI.parse request_url
    request = ::HTTP::Request.new("GET", uri.path.presence ? uri.path : "/", headers: ::HTTP::Headers{"host" => uri.hostname || ""})

    authorization = AMC::Authorization.new registry

    expect_raises AMC::Exception::InvalidArgument, "Unable to create authorization cookie for a hub on the different second-level domain" do
      authorization.create_cookie request
    end
  end

  def nonapplicable_cookie_domains : Tuple
    {
      {"https://demo.mercure.com", "https://example.com"},
      {"https://mercure.internal.com", "https://external.com"},
    }
  end

  def test_set_multiple_cookies : Nil
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::TokenFactory::JWT.new("looooooooooooongenoughtestsecret", jwt_lifetime: 4000, protocol_version: :legacy)
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "https://example.com", headers: ::HTTP::Headers{"host" => "example.com"})
    response = ::HTTP::Server::Response.new IO::Memory.new

    authorization = AMC::Authorization.new registry

    expect_raises AMC::Exception::Runtime, "The '__Secure-mercure_access_token' cookie for the 'default hub' has already been set. You cannot set it two times during the same request." do
      authorization.set_cookie request, response
      authorization.clear_cookie request, response
    end
  end

  def test_no_grants : Nil
    token_factory = AMC::Spec::AssertingTokenFactory.new(
      "JWT",
      additional_claims: {"x-foo" => "baz"},
    )

    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: token_factory
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "https://example.com", headers: ::HTTP::Headers{"host" => "example.com"})
    response = ::HTTP::Server::Response.new IO::Memory.new

    authorization = AMC::Authorization.new registry
    authorization.set_cookie request, response, additional_claims: {"x-foo" => "baz"}
    token_factory.called?.should be_true

    cookie = response.cookies.first
    cookie.value.should_not be_empty
  end

  @[DataProvider("grant_shorthands")]
  def test_grant_shorthands(grants : Array(String) | Hash(String, Array(String)) | String, expected : Array(AMC::Grant)) : Nil
    token_factory = AMC::Spec::AssertingTokenFactory.new "JWT", expected

    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: token_factory
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "https://example.com", headers: ::HTTP::Headers{"host" => "example.com"})

    AMC::Authorization.new(registry).create_cookie(request, grants).value.should eq "JWT"
    token_factory.called?.should be_true
  end

  def grant_shorthands : Tuple
    {
      {"foo", [AMC::Grant.new(:subscribe, ["foo"])]},
      {["foo", "bar"], [AMC::Grant.new(:subscribe, ["foo", "bar"])]},
      { {"urlpattern" => ["https://example.com/books/:id"]}, [AMC::Grant.new(:subscribe, {"urlpattern" => ["https://example.com/books/:id"]})] },
    }
  end

  def test_cookie_name_comes_from_the_hub : Nil
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "https://example.com",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::Spec::AssertingTokenFactory.new("JWT"),
      protocol_version: :legacy,
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "https://example.com", headers: ::HTTP::Headers{"host" => "example.com"})

    cookie = AMC::Authorization.new(registry).create_cookie request
    cookie.name.should eq "mercureAuthorization"
    cookie.path.should eq "/"
  end

  def test_prefixed_cookie_name_on_plain_http_hub : Nil
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "http://localhost/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::Spec::AssertingTokenFactory.new("JWT"),
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "http://localhost", headers: ::HTTP::Headers{"host" => "localhost"})

    authorization = AMC::Authorization.new registry

    expect_raises AMC::Exception::InvalidArgument, "The '__Secure-mercure_access_token' cookie name requires a hub public URL served over HTTPS. Configure a cookie name without a prefix on the hub for plain HTTP development." do
      authorization.create_cookie request
    end

    expect_raises AMC::Exception::InvalidArgument, "The '__Secure-mercure_access_token' cookie name requires a hub public URL served over HTTPS." do
      authorization.clear_cookie request, ::HTTP::Server::Response.new(IO::Memory.new)
    end
  end

  def test_prefix_less_cookie_name_on_plain_http_hub : Nil
    registry = AMC::Hub::Registry.new(AMC::Spec::MockHub.new(
      "http://localhost/.well-known/mercure",
      AMC::TokenProvider::Static.new("JWT"),
      token_factory: AMC::Spec::AssertingTokenFactory.new("JWT"),
      cookie_name: "mercure_access_token",
    ) { "ID" })

    request = ::HTTP::Request.new("GET", "http://localhost", headers: ::HTTP::Headers{"host" => "localhost"})
    response = ::HTTP::Server::Response.new IO::Memory.new

    authorization = AMC::Authorization.new registry

    cookie = authorization.create_cookie request
    cookie.name.should eq "mercure_access_token"
    cookie.secure.should be_false

    authorization.clear_cookie request, response

    cookie = response.cookies["mercure_access_token"]
    cookie.value.should be_empty
    cookie.secure.should be_false
  end
end
