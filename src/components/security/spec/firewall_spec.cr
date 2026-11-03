require "./spec_helper"

# Returns the provided listeners for every request, while recording how many times it was called.
private class MockFirewallMap
  include ASEC::FirewallMapInterface

  getter calls = 0

  def initialize(@listeners : Array(ASEC::Firewall::ListenerInterface) = [] of ASEC::Firewall::ListenerInterface, @exception_listener : ASEC::Firewall::ExceptionListener? = nil); end

  def listeners(request : AHTTP::Request) : Tuple(Array(ASEC::Firewall::ListenerInterface), ASEC::Firewall::ExceptionListener?)
    @calls += 1

    {@listeners, @exception_listener}
  end
end

struct FirewallTest < ASPEC::TestCase
  def test_on_exception_calls_the_exception_listener : Nil
    request = new_request
    entry_point = MockEntryPoint.new
    exception = ASEC::Exception::BadCredentials.new
    exception_listener = ASEC::Firewall::ExceptionListener.new ASEC::Authentication::Token::Storage.new, ASEC::Authentication::TrustResolver.new, "main", entry_point
    map = MockFirewallMap.new exception_listener: exception_listener

    dispatcher = AED::EventDispatcher.new
    dispatcher.listener ASEC::Firewall.new map

    dispatcher.dispatch AHK::Events::Request.new request
    dispatcher.dispatch event = AHK::Events::Exception.new(request, exception)

    map.calls.should eq 1
    entry_point.exceptions.should eq [exception]
    event.response.try(&.content).should eq "OK"
  end

  def test_on_exception_without_exception_listener : Nil
    request = new_request
    firewall = ASEC::Firewall.new MockFirewallMap.new

    firewall.on_request AHK::Events::Request.new request
    firewall.on_exception event = AHK::Events::Exception.new(request, ASEC::Exception::BadCredentials.new)

    event.response.should be_nil
  end

  def test_on_exception_only_handles_the_exceptions_of_requests_handled_by_the_firewall : Nil
    entry_point = MockEntryPoint.new
    firewall = ASEC::Firewall.new MockFirewallMap.new(exception_listener: ASEC::Firewall::ExceptionListener.new(ASEC::Authentication::Token::Storage.new, ASEC::Authentication::TrustResolver.new, "main", entry_point))

    firewall.on_request AHK::Events::Request.new new_request
    firewall.on_exception event = AHK::Events::Exception.new(new_request, ASEC::Exception::BadCredentials.new)

    event.response.should be_nil
    entry_point.exceptions.should be_empty
  end

  def test_on_request_stops_when_there_is_a_response : Nil
    calls = [] of String
    response = AHTTP::Response.new
    map = MockFirewallMap.new [
      MockFirewallListener.new("first", calls, response: response),
      MockFirewallListener.new("second", calls),
    ] of ASEC::Firewall::ListenerInterface

    ASEC::Firewall.new(map).on_request event = AHK::Events::Request.new(new_request)

    calls.should eq ["first"]
    event.response.should be response
    map.calls.should eq 1
  end

  def test_firewall_listeners_are_called : Nil
    calls = [] of String
    map = MockFirewallMap.new [
      MockFirewallListener.new("firewall_listener", calls),
      MockFirewallListener.new("lazy_firewall_listener", calls, supports: nil),
      MockFirewallListener.new("unsupported_firewall_listener", calls, supports: false),
      MockFirewallListener.new("last_firewall_listener", calls),
    ] of ASEC::Firewall::ListenerInterface

    ASEC::Firewall.new(map).on_request event = AHK::Events::Request.new(new_request)

    calls.should eq ["firewall_listener", "lazy_firewall_listener", "last_firewall_listener"]
    event.response.should be_nil
  end
end

# Authenticates the user whose identifier is in the `x-user` header, failing with a `401` response if it does not exist.
private class HeaderAuthenticator < ASEC::Authenticator::AbstractAuthenticator
  def supports?(request : AHTTP::Request) : Bool?
    request.headers.has_key? "x-user"
  end

  def authenticate(request : AHTTP::Request) : ASEC::Authenticator::Passport
    ASEC::Authenticator::Passport::SelfValidating.new ASEC::Authenticator::Passport::Badge::User.new(request.headers["x-user"])
  end

  def on_authentication_success(request : AHTTP::Request, token : ASEC::Authentication::Token::Interface, firewall_name : String) : AHTTP::Response?
    nil
  end

  def on_authentication_failure(request : AHTTP::Request, exception : ASEC::Exception::Authentication) : AHTTP::Response?
    AHTTP::Response.new exception.message_key, :unauthorized
  end
end

private struct SecuredActionResolver
  include AHK::ActionResolverInterface

  def resolve(request : AHTTP::Request) : AHK::ActionBase?
    AHK::Action.new(
      Proc(typeof(Tuple.new), AHTTP::Response).new { AHTTP::Response.new "Secured" },
      Tuple.new,
      AHTTP::Response,
    )
  end
end

private struct NoArgumentsResolver
  include AHK::Controller::ArgumentResolverInterface

  def get_arguments(request : AHTTP::Request, action : AHK::ActionBase) : Array
    [] of String
  end
end

struct FirewallHTTPKernelTest < ASPEC::TestCase
  @token_storage : ASEC::Authentication::Token::Storage

  def initialize
    @token_storage = ASEC::Authentication::Token::Storage.new
  end

  def test_authenticated_user_granted_access : Nil
    response = self.handle "/admin", "admin"

    response.status.should eq ::HTTP::Status::OK
    response.content.should eq "Secured"
    @token_storage.token.try(&.user_identifier).should eq "admin"
  end

  def test_authenticated_user_denied_access : Nil
    response = self.handle "/admin", "user"

    response.status.should eq ::HTTP::Status::FORBIDDEN
    response.content.should contain "Access Denied."
  end

  def test_public_access : Nil
    self.handle("/", nil).status.should eq ::HTTP::Status::OK
  end

  def test_access_without_user_and_entry_point : Nil
    response = self.handle "/admin", nil

    response.status.should eq ::HTTP::Status::UNAUTHORIZED
    response.content.should contain "Full authentication is required to access this resource."
  end

  def test_access_without_user_starts_the_authentication : Nil
    response = self.handle "/admin", nil, MockEntryPoint.new(AHTTP::RedirectResponse.new "/login")

    response.status.should eq ::HTTP::Status::FOUND
    response.headers["location"].should eq "/login"
  end

  def test_authentication_failure : Nil
    response = self.handle "/admin", "unknown"

    response.status.should eq ::HTTP::Status::UNAUTHORIZED
    response.content.should eq "Invalid credentials."
    @token_storage.token.should be_nil
  end

  private def handle(path : String, user : String?, entry_point : ASEC::EntryPoint::Interface? = nil) : AHTTP::Response
    firewall_dispatcher = AED::EventDispatcher.new
    firewall_dispatcher.listener ASEC::Listeners::UserProvider.new ASEC::User::Provider::InMemory.new [
      ASEC::User::InMemory.new("admin", nil, ["ROLE_ADMIN"]),
      ASEC::User::InMemory.new("user", nil, ["ROLE_USER"]),
    ]

    access_map = ASEC::AccessMap.new
    access_map.add AHTTP::RequestMatcher::Path.new(%r(^/admin)), "ROLE_ADMIN"
    access_map.add AHTTP::RequestMatcher::Path.new(%r(^/)), ASEC::Authorization::Voter::Authenticated::PUBLIC_ACCESS

    trust_resolver = ASEC::Authentication::TrustResolver.new
    access_decision_manager = ASEC::Authorization::AccessDecisionManager.new [
      ASEC::Authorization::Voter::Authenticated.new(trust_resolver),
      ASEC::Authorization::Voter::Role.new,
    ] of ASEC::Authorization::Voter

    firewall_map = ASEC::FirewallMap.new
    firewall_map.add(
      listeners: [
        ASEC::Firewall::AccessListener.new(@token_storage, access_decision_manager, access_map),
        ASEC::Firewall::AuthenticatorManagerListener.new(
          ASEC::Authentication::AuthenticatorManager.new([HeaderAuthenticator.new] of ASEC::Authenticator::Interface, @token_storage, firewall_dispatcher, "main"),
        ),
      ] of ASEC::Firewall::ListenerInterface,
      exception_listener: ASEC::Firewall::ExceptionListener.new(@token_storage, trust_resolver, "main", entry_point),
    )

    dispatcher = AED::EventDispatcher.new
    dispatcher.listener ASEC::Firewall.new firewall_map
    dispatcher.listener AHK::Listeners::Error.new AHK::ErrorRenderer.new(false)

    headers = ::HTTP::Headers.new
    headers["x-user"] = user if user

    AHK::HTTPKernel.new(dispatcher, AHTTP::RequestStore.new, NoArgumentsResolver.new, SecuredActionResolver.new).handle AHTTP::Request.new("GET", path, headers)
  end
end
