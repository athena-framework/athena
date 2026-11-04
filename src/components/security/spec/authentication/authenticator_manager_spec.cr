require "../spec_helper"

struct AuthenticatorManagerTest < ASPEC::TestCase
  @token_storage : ASEC::Authentication::Token::Storage
  @event_dispatcher : AED::EventDispatcher
  @request : AHTTP::Request
  @user : ASEC::User::InMemory
  @token : ASEC::Authentication::Token::Interface
  @response : AHTTP::Response

  def initialize
    @token_storage = ASEC::Authentication::Token::Storage.new
    @event_dispatcher = AED::EventDispatcher.new
    @request = new_request
    @user = ASEC::User::InMemory.new "wouter", nil
    @token = ASEC::Authentication::Token::UsernamePassword.new @user, "main"
    @response = AHTTP::Response.new
  end

  @[DataProvider("supports_data")]
  def test_supports(supports : Array(Bool?), result : Bool?) : Nil
    authenticators = supports.map { |s| MockAuthenticator.new(s).as ASEC::Authenticator::Interface }

    self.create_manager(authenticators).supports?(@request).should eq result
  end

  def supports_data : Tuple
    {
      {[nil, nil] of Bool?, nil},
      {[nil, false] of Bool?, nil},
      {[nil, true] of Bool?, true},
      {[true, false] of Bool?, true},
      {[false, false] of Bool?, false},
      {[] of Bool?, false},
    }
  end

  def test_supports_logs_the_checked_authenticators : Nil
    manager = self.create_manager [MockAuthenticator.new(false), MockAuthenticator.new(true)] of ASEC::Authenticator::Interface

    Log.capture "athena.security", :debug do |logs|
      manager.supports?(@request).should be_true

      logs.check :debug, "Checked for authenticator support."
      logs.entry.data.to_h.should eq({
        :firewall_name             => Log::Metadata::Value.new("main"),
        :supporting_authenticators => Log::Metadata::Value.new(["MockAuthenticator"]),
        :skipped_authenticators    => Log::Metadata::Value.new(["MockAuthenticator"]),
      })
    end
  end

  def test_support_checked_upon_request_authentication : Nil
    # The supporting authenticators are stored on the request, but an authenticator not supporting it anymore means that its support changed after `#supports?`, e.g. with lazy authentication.
    authenticator = MockAuthenticator.new
    manager = self.create_manager [authenticator] of ASEC::Authenticator::Interface

    manager.supports?(@request).should be_true
    authenticator.supports = false

    manager.authenticate_request(@request).should be_nil
    authenticator.authenticate_calls.should eq 0
  end

  def test_authenticate_request_without_supports : Nil
    authenticator = MockAuthenticator.new

    self.create_manager([authenticator] of ASEC::Authenticator::Interface).authenticate_request(@request).should be_nil
    authenticator.authenticate_calls.should eq 0
  end

  @[DataProvider("matching_authenticator_index")]
  def test_authenticate_request(matching_authenticator_index : Int32) : Nil
    matching_authenticator = MockAuthenticator.new(
      passport: ASEC::Authenticator::Passport::SelfValidating.new(ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user }),
      token: @token,
    )
    not_matching_authenticator = MockAuthenticator.new false

    authenticators = [matching_authenticator, not_matching_authenticator] of ASEC::Authenticator::Interface
    authenticators.reverse! if matching_authenticator_index == 1

    listener_called = false
    @event_dispatcher.listener ASEC::Events::CheckPassport do |event|
      listener_called = true if event.authenticator.same?(matching_authenticator) && event.passport.user.same?(@user)
    end

    manager = self.create_manager authenticators
    manager.supports?(@request).should be_true

    manager.authenticate_request(@request).should be_nil
    listener_called.should be_true
    @token_storage.token.should be @token
    not_matching_authenticator.authenticate_calls.should eq 0
    matching_authenticator.success_calls.should eq [{@token, "main"}]
  end

  def matching_authenticator_index : Tuple
    {
      {0},
      {1},
    }
  end

  def test_authenticate_request_dispatches_the_events : Nil
    previous_token = TestToken.new
    @token_storage.token = previous_token
    authenticator = MockAuthenticator.new token: @token
    events = [] of String

    @event_dispatcher.listener(ASEC::Events::CheckPassport) { events << "check_passport" }
    @event_dispatcher.listener(ASEC::Events::AuthenticationTokenCreated) { events << "authentication_token_created" }
    @event_dispatcher.listener(ASEC::Events::AuthenticationSuccess) do |event|
      event.authentication_token.should be @token
      events << "authentication_success"
    end
    @event_dispatcher.listener(ASEC::Events::LoginSuccess) do |event|
      event.authenticator.should be authenticator
      event.authenticated_token.should be @token
      event.previous_token.should be previous_token
      event.request.should be @request
      event.firewall_name.should eq "main"
      event.response.should be_nil
      event.user.user_identifier.should eq "user"
      events << "login_success"
    end

    self.authenticate(authenticator).should be_nil

    events.should eq ["check_passport", "authentication_token_created", "authentication_success", "login_success"]
  end

  def test_authenticate_request_returns_the_success_response : Nil
    authenticator = MockAuthenticator.new token: @token, success_response: @response
    other_authenticator = MockAuthenticator.new

    manager = self.create_manager [authenticator, other_authenticator] of ASEC::Authenticator::Interface
    manager.supports? @request

    manager.authenticate_request(@request).should be @response
    other_authenticator.authenticate_calls.should eq 0
  end

  def test_login_success_listener_can_replace_the_response : Nil
    authenticator = MockAuthenticator.new token: @token, success_response: @response
    replaced_response = AHTTP::Response.new "replaced"

    @event_dispatcher.listener(ASEC::Events::LoginSuccess) do |event|
      event.response.should be @response
      event.response = replaced_response
    end

    self.authenticate(authenticator).should be replaced_response
  end

  def test_no_credentials_validated : Nil
    authenticator = MockAuthenticator.new passport: ASEC::Authenticator::Passport.new(
      ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user },
      ASEC::Authenticator::Passport::Credentials::Password.new("pass"),
    )

    self.authenticate(authenticator).should be_nil

    exception = authenticator.failure_exceptions.first.should be_a ASEC::Exception::BadCredentials
    exception.message.should eq "Authentication failed: Security badge 'Athena::Security::Authenticator::Passport::Credentials::Password' is not resolved, did you forget to register the correct listeners?"
    @token_storage.token.should be_nil
  end

  def test_authenticate_request_can_modify_token_from_event : Nil
    authenticator = MockAuthenticator.new token: @token
    modified_token = ASEC::Authentication::Token::UsernamePassword.new @user, "main"
    listener_called = false

    @event_dispatcher.listener ASEC::Events::AuthenticationTokenCreated do |event|
      event.authenticated_token = modified_token
      listener_called = true
    end

    self.authenticate(authenticator).should be_nil
    listener_called.should be_true
    @token_storage.token.should be modified_token
    authenticator.success_calls.should eq [{modified_token, "main"}]
  end

  def test_authentication_success_listener_can_reject_the_authentication : Nil
    authenticator = MockAuthenticator.new token: @token, failure_response: @response
    exception = ASEC::Exception::CustomUserMessageAuthentication.new "Rejected."

    @event_dispatcher.listener(ASEC::Events::AuthenticationSuccess) { raise exception }

    self.authenticate(authenticator).should be @response
    authenticator.failure_exceptions.should eq [exception]
    authenticator.success_calls.should be_empty
    @token_storage.token.should be_nil
  end

  def test_authenticate_request_dispatches_login_failure : Nil
    exception = ASEC::Exception::BadCredentials.new "Bad."
    authenticator = MockAuthenticator.new passport: exception, failure_response: @response
    replaced_response = AHTTP::Response.new "replaced"

    @event_dispatcher.listener(ASEC::Events::LoginFailure) do |event|
      event.exception.should be exception
      event.authenticator.should be authenticator
      event.request.should be @request
      event.response.should be @response
      event.firewall_name.should eq "main"
      event.passport.should be_nil

      event.response = replaced_response
    end

    self.authenticate(authenticator).should be replaced_response
  end

  def test_login_failure_event_has_the_passport : Nil
    passport = ASEC::Authenticator::Passport.new(
      ASEC::Authenticator::Passport::Badge::User.new("wouter") { @user },
      ASEC::Authenticator::Passport::Credentials::Password.new("pass"),
    )
    login_failure_passport = nil

    @event_dispatcher.listener(ASEC::Events::LoginFailure) { |event| login_failure_passport = event.passport }

    self.authenticate(MockAuthenticator.new passport: passport).should be_nil
    login_failure_passport.should be passport
  end

  def test_authenticate_request_hides_invalid_user_exceptions : Nil
    invalid_user_exception = ASEC::Exception::UserNotFound.new
    authenticator = MockAuthenticator.new passport: invalid_user_exception, failure_response: @response

    self.authenticate(authenticator, expose_security_errors: :account_status).should be @response

    exception = authenticator.failure_exceptions.first.should be_a ASEC::Exception::BadCredentials
    exception.message.should eq "Bad credentials."
    exception.cause.should be invalid_user_exception
  end

  def test_authenticate_request_shows_invalid_user_exceptions : Nil
    invalid_user_exception = ASEC::Exception::UserNotFound.new
    authenticator = MockAuthenticator.new passport: invalid_user_exception

    self.authenticate authenticator, expose_security_errors: :all

    authenticator.failure_exceptions.should eq [invalid_user_exception]
  end

  def test_authenticate_request_shows_account_status_exception : Nil
    invalid_user_exception = ASEC::Exception::Disabled.new
    authenticator = MockAuthenticator.new passport: invalid_user_exception, failure_response: @response

    self.authenticate(authenticator, expose_security_errors: :account_status).should be @response

    authenticator.failure_exceptions.should eq [invalid_user_exception]
  end

  def test_authenticate_request_hides_invalid_account_status_exception : Nil
    invalid_user_exception = ASEC::Exception::Disabled.new
    authenticator = MockAuthenticator.new passport: invalid_user_exception, failure_response: @response

    self.authenticate(authenticator).should be @response

    exception = authenticator.failure_exceptions.first.should be_a ASEC::Exception::BadCredentials
    exception.cause.should be invalid_user_exception
  end

  def test_authenticate_request_shows_custom_user_message_account_status_exception : Nil
    invalid_user_exception = ASEC::Exception::CustomUserMessageAccountStatus.new "Your account was banned."
    authenticator = MockAuthenticator.new passport: invalid_user_exception

    self.authenticate authenticator

    authenticator.failure_exceptions.should eq [invalid_user_exception]
  end

  def test_authenticate_request_does_not_rescue_other_exceptions : Nil
    authenticator = MockAuthenticator.new passport: ASEC::Exception::Logic.new("Logic.")

    expect_raises ASEC::Exception::Logic, "Logic." do
      self.authenticate authenticator
    end
  end

  def test_logs_the_authenticator : Nil
    authenticator = MockAuthenticator.new token: @token, success_response: @response

    Log.capture "athena.security", :debug do |logs|
      self.authenticate(authenticator).should be @response

      logs.check :debug, "Checked for authenticator support."
      logs.next :info, "Authenticator successful!"
      logs.entry.data[:authenticator].should eq "MockAuthenticator"
      logs.next :debug, "The authenticator set the response. Any later authenticator will not be called."
    end
  end

  private def authenticate(authenticator : ASEC::Authenticator::Interface, expose_security_errors : ASEC::Authentication::ExposeSecurityLevel = :none) : AHTTP::Response?
    manager = self.create_manager [authenticator] of ASEC::Authenticator::Interface, expose_security_errors
    manager.supports? @request

    manager.authenticate_request @request
  end

  private def create_manager(authenticators : Array(ASEC::Authenticator::Interface), expose_security_errors : ASEC::Authentication::ExposeSecurityLevel = :none) : ASEC::Authentication::AuthenticatorManager
    ASEC::Authentication::AuthenticatorManager.new authenticators, @token_storage, @event_dispatcher, "main", expose_security_errors
  end
end
