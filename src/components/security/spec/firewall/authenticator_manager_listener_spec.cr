require "../spec_helper"

struct AuthenticatorManagerListenerTest < ASPEC::TestCase
  @token_storage : ASEC::Authentication::Token::Storage

  def initialize
    @token_storage = ASEC::Authentication::Token::Storage.new
  end

  @[DataProvider("supports_data")]
  def test_supports(supports : Bool?) : Nil
    self.create_listener(MockAuthenticator.new supports).supports?(new_request).should eq supports
  end

  def supports_data : Tuple
    {
      {true},
      {false},
      {nil},
    }
  end

  def test_authenticate_sets_the_response : Nil
    request = new_request
    response = AHTTP::Response.new
    listener = self.create_listener MockAuthenticator.new(success_response: response)

    listener.supports? request
    listener.authenticate event = AHK::Events::Request.new(request)

    event.response.should be response
    event.propagate?.should be_false
    @token_storage.token.should_not be_nil
  end

  def test_authenticate_without_response : Nil
    request = new_request
    listener = self.create_listener MockAuthenticator.new

    listener.supports? request
    listener.authenticate event = AHK::Events::Request.new(request)

    event.response.should be_nil
    event.propagate?.should be_true
    @token_storage.token.should_not be_nil
  end

  def test_priority : Nil
    self.create_listener(MockAuthenticator.new).priority.should eq 0
  end

  private def create_listener(authenticator : ASEC::Authenticator::Interface) : ASEC::Firewall::AuthenticatorManagerListener
    ASEC::Firewall::AuthenticatorManagerListener.new ASEC::Authentication::AuthenticatorManager.new(
      [authenticator] of ASEC::Authenticator::Interface,
      @token_storage,
      AED::EventDispatcher.new,
      "main"
    )
  end
end
