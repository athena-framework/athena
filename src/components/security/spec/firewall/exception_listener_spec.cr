require "../spec_helper"

# Raises the provided *exception* when started.
private class RaisingEntryPoint
  include ASEC::EntryPoint::Interface

  def initialize(@exception : ::Exception); end

  def start(request : AHTTP::Request, exception : ASEC::Exception::Authentication? = nil) : AHTTP::Response
    raise @exception
  end
end

struct ExceptionListenerTest < ASPEC::TestCase
  @[DataProvider("authentication_exceptions")]
  def test_authentication_exception_without_entry_point(exception : ::Exception, authentication_exception : ASEC::Exception::Authentication, message : String) : Nil
    event = self.create_event exception

    self.create_exception_listener.on_exception event

    event.response.should be_nil

    http_exception = event.exception.should be_a AHK::Exception::HTTPException
    http_exception.status.should eq ::HTTP::Status::UNAUTHORIZED
    http_exception.message.should eq message
    http_exception.cause.should be authentication_exception
  end

  @[DataProvider("authentication_exceptions")]
  def test_authentication_exception_with_entry_point(exception : ::Exception, authentication_exception : ASEC::Exception::Authentication, message : String) : Nil
    event = self.create_event exception
    entry_point = MockEntryPoint.new AHTTP::Response.new("Forbidden", :forbidden)

    self.create_exception_listener(entry_point: entry_point).on_exception event

    event.response.try(&.content).should eq "Forbidden"
    event.response.try(&.status).should eq ::HTTP::Status::FORBIDDEN
    event.exception.should be exception
    entry_point.exceptions.should eq [authentication_exception]
  end

  def authentication_exceptions : Tuple
    {
      {e = ASEC::Exception::Authentication.new, e, ""},
      {ASEC::Exception::Logic.new("random", e = ASEC::Exception::Authentication.new), e, ""},
      {ASEC::Exception::Logic.new("random", e = ASEC::Exception::Authentication.new("embed", ASEC::Exception::Authentication.new)), e, "embed"},
      {ASEC::Exception::Logic.new("random", e = ASEC::Exception::Authentication.new("embed", ASEC::Exception::AccessDenied.new)), e, "embed"},
      {e = ASEC::Exception::Authentication.new("random", ASEC::Exception::Logic.new), e, "random"},
    }
  end

  @[DataProvider("access_denied_exceptions")]
  def test_access_denied_exception_full_fledged(exception : ::Exception, access_denied_exception : ASEC::Exception::AccessDenied) : Nil
    event = self.create_event exception
    trust_resolver = MockTrustResolver.new true

    self.create_exception_listener(trust_resolver: trust_resolver).on_exception event

    event.response.should be_nil
    trust_resolver.full_fledged_calls.should eq 1

    http_exception = event.exception.should be_a AHK::Exception::Forbidden
    http_exception.message.should eq access_denied_exception.message
    http_exception.cause.should be access_denied_exception
  end

  @[DataProvider("access_denied_exceptions")]
  def test_access_denied_exception_not_full_fledged(exception : ::Exception, access_denied_exception : ASEC::Exception::AccessDenied) : Nil
    event = self.create_event exception
    token_storage = ASEC::Authentication::Token::Storage.new
    token = TestToken.new
    token_storage.token = token
    entry_point = MockEntryPoint.new

    self.create_exception_listener(token_storage, MockTrustResolver.new(false), entry_point).on_exception event

    event.response.try(&.content).should eq "OK"
    event.exception.should be exception

    insufficient_authentication_exception = entry_point.exceptions.first.should be_a ASEC::Exception::InsufficientAuthentication
    insufficient_authentication_exception.message.should eq "Full authentication is required to access this resource."
    insufficient_authentication_exception.cause.should be access_denied_exception
    insufficient_authentication_exception.token.should be token
  end

  def access_denied_exceptions : Tuple
    {
      {e = ASEC::Exception::AccessDenied.new, e},
      {ASEC::Exception::Logic.new("random", e = ASEC::Exception::AccessDenied.new), e},
      {ASEC::Exception::Logic.new("random", e = ASEC::Exception::AccessDenied.new("embed", ASEC::Exception::AccessDenied.new)), e},
      {ASEC::Exception::Logic.new("random", e = ASEC::Exception::AccessDenied.new("embed", ASEC::Exception::Authentication.new)), e},
      {e = ASEC::Exception::AccessDenied.new("random", ASEC::Exception::Logic.new), e},
    }
  end

  def test_access_denied_exception_not_full_fledged_without_entry_point : Nil
    exception = ASEC::Exception::AccessDenied.new
    event = self.create_event exception

    self.create_exception_listener(trust_resolver: MockTrustResolver.new(false)).on_exception event

    event.response.should be_nil

    http_exception = event.exception.should be_a AHK::Exception::HTTPException
    http_exception.status.should eq ::HTTP::Status::UNAUTHORIZED
    http_exception.message.should eq "Full authentication is required to access this resource."
    http_exception.cause.should be_a ASEC::Exception::InsufficientAuthentication
  end

  def test_account_status_exception_removes_the_token : Nil
    token_storage = ASEC::Authentication::Token::Storage.new
    token_storage.token = TestToken.new
    entry_point = MockEntryPoint.new

    self.create_exception_listener(token_storage, entry_point: entry_point).on_exception self.create_event(ASEC::Exception::Disabled.new)

    token_storage.token.should be_nil
    entry_point.exceptions.size.should eq 1
  end

  def test_authentication_exception_keeps_the_token : Nil
    token_storage = ASEC::Authentication::Token::Storage.new
    token = TestToken.new
    token_storage.token = token

    self.create_exception_listener(token_storage, entry_point: MockEntryPoint.new).on_exception self.create_event(ASEC::Exception::BadCredentials.new)

    token_storage.token.should be token
  end

  def test_exception_raised_by_the_entry_point : Nil
    exception = ASEC::Exception::Logic.new "Entry point failed."
    event = self.create_event ASEC::Exception::BadCredentials.new

    self.create_exception_listener(entry_point: RaisingEntryPoint.new(exception)).on_exception event

    event.response.should be_nil
    event.exception.should be exception
  end

  def test_exception_raised_by_the_entry_point_on_access_denied : Nil
    exception = ASEC::Exception::Logic.new "Entry point failed."
    event = self.create_event ASEC::Exception::AccessDenied.new

    self.create_exception_listener(trust_resolver: MockTrustResolver.new(false), entry_point: RaisingEntryPoint.new(exception)).on_exception event

    event.response.should be_nil
    event.exception.should be exception
  end

  def test_other_exceptions_are_ignored : Nil
    exception = ASEC::Exception::Logic.new "random", ::Exception.new("cause")
    event = self.create_event exception

    self.create_exception_listener(entry_point: MockEntryPoint.new).on_exception event

    event.response.should be_nil
    event.exception.should be exception
  end

  private def create_event(exception : ::Exception) : AHK::Events::Exception
    AHK::Events::Exception.new new_request, exception
  end

  private def create_exception_listener(
    token_storage : ASEC::Authentication::Token::Storage::Interface = ASEC::Authentication::Token::Storage.new,
    trust_resolver : ASEC::Authentication::TrustResolverInterface = MockTrustResolver.new(false),
    entry_point : ASEC::EntryPoint::Interface? = nil,
  ) : ASEC::Firewall::ExceptionListener
    ASEC::Firewall::ExceptionListener.new token_storage, trust_resolver, "key", entry_point
  end
end
