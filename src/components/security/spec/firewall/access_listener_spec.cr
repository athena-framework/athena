require "../spec_helper"

struct AccessListenerTest < ASPEC::TestCase
  @token_storage : ASEC::Authentication::Token::Storage
  @access_map : ASEC::AccessMap

  def initialize
    @token_storage = ASEC::Authentication::Token::Storage.new
    @access_map = ASEC::AccessMap.new
  end

  def test_handle_when_the_access_decision_manager_decides_to_refuse_access : Nil
    request = new_request
    token = TestToken.new
    @token_storage.token = token
    voter = MockAttributeVoter.new :denied, reason: "Not an admin."
    @access_map.add MockRequestMatcher.new(true), "ROLE_ADMIN"

    listener = self.create_listener voter

    listener.supports?(request).should be_true

    ex = expect_raises ASEC::Exception::AccessDenied, "Access Denied. Not an admin." do
      listener.authenticate AHK::Events::Request.new request
    end

    ex.attribute.should eq "ROLE_ADMIN"
    ex.access_decision.try(&.granted?).should be_false
    ex.access_decision.try(&.votes.size).should eq 1
    voter.calls.should eq [{token, "ROLE_ADMIN"}]
  end

  def test_handle_when_the_access_decision_manager_grants_access : Nil
    request = new_request
    voter = MockAttributeVoter.new :granted
    @access_map.add MockRequestMatcher.new(true), "ROLE_ADMIN"

    listener = self.create_listener voter

    listener.supports?(request).should be_true
    listener.authenticate AHK::Events::Request.new request

    request.attributes.has?("_access_control_attribute").should be_false
  end

  def test_handle_when_there_is_no_access_map_entry_matching_the_request : Nil
    request = new_request
    voter = MockAttributeVoter.new
    @access_map.add MockRequestMatcher.new(false), "ROLE_ADMIN"

    listener = self.create_listener voter

    listener.supports?(request).should be_nil
    listener.authenticate AHK::Events::Request.new request

    voter.calls.should be_empty
  end

  def test_handle_when_access_map_returns_no_attribute : Nil
    request = new_request
    voter = MockAttributeVoter.new
    @access_map.add MockRequestMatcher.new(true)

    listener = self.create_listener voter

    listener.supports?(request).should be_nil
    listener.authenticate AHK::Events::Request.new request

    voter.calls.should be_empty
  end

  def test_handle_when_the_security_token_storage_has_no_token : Nil
    request = new_request
    voter = MockAttributeVoter.new :denied
    @access_map.add MockRequestMatcher.new(true), "ROLE_ADMIN"

    listener = self.create_listener voter

    listener.supports?(request).should be_true

    expect_raises ASEC::Exception::AccessDenied do
      listener.authenticate AHK::Events::Request.new request
    end

    voter.calls.first[0].should be_a ASEC::Authentication::Token::Null
  end

  def test_handle_when_public_access_is_allowed : Nil
    request = new_request
    @access_map.add MockRequestMatcher.new(true), ASEC::Authorization::Voter::Authenticated::PUBLIC_ACCESS

    listener = self.create_listener ASEC::Authorization::Voter::Authenticated.new(ASEC::Authentication::TrustResolver.new)

    listener.supports?(request).should be_nil
    listener.authenticate AHK::Events::Request.new request
  end

  def test_handle_when_public_access_while_authenticated : Nil
    request = new_request
    token = ASEC::Authentication::Token::UsernamePassword.new ASEC::User::InMemory.new("Wouter", nil, ["ROLE_USER"]), "main", ["ROLE_USER"]
    @token_storage.token = token
    voter = MockAttributeVoter.new :granted
    @access_map.add MockRequestMatcher.new(true), ASEC::Authorization::Voter::Authenticated::PUBLIC_ACCESS

    listener = self.create_listener voter

    listener.supports?(request).should be_nil
    listener.authenticate AHK::Events::Request.new request

    voter.calls.should eq [{token, ASEC::Authorization::Voter::Authenticated::PUBLIC_ACCESS}]
  end

  def test_the_request_is_the_subject : Nil
    request = new_request
    voter = RequestVoter.new
    @access_map.add MockRequestMatcher.new(true), "REQUEST"

    listener = self.create_listener voter

    listener.supports? request
    listener.authenticate AHK::Events::Request.new request

    voter.subjects.should eq [request]
  end

  def test_priority : Nil
    self.create_listener(MockAttributeVoter.new).priority.should eq -255
  end

  private def create_listener(voter : ASEC::Authorization::Voter) : ASEC::Firewall::AccessListener
    ASEC::Firewall::AccessListener.new(
      @token_storage,
      ASEC::Authorization::AccessDecisionManager.new([voter] of ASEC::Authorization::Voter),
      @access_map,
    )
  end
end

# Grants the access to requests, while recording them.
class RequestVoter < ASEC::Authorization::Voter
  include ASEC::Authorization::Voter::Subject(AHTTP::Request, String)

  getter subjects = [] of AHTTP::Request

  protected def supports?(attribute : String, subject : AHTTP::Request) : Bool
    attribute == "REQUEST"
  end

  protected def vote_on_attribute(attribute : String, subject : AHTTP::Request, token : ASEC::Authentication::Token::Interface, vote : ASEC::Authorization::Voter::Vote?) : Bool
    @subjects << subject

    true
  end
end
