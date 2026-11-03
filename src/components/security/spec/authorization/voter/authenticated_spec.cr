require "../../spec_helper"

struct AuthenticatedVoterTest < ASPEC::TestCase
  @[DataProvider("vote_tests")]
  def test_vote(authenticated : Bool, attribute : String, expected : ASEC::Authorization::Voter::Access, reason : String?) : Nil
    token = authenticated ? TestToken.new(user: TestUser.new) : ASEC::Authentication::Token::Null.new
    vote = ASEC::Authorization::Voter::Vote.new

    ASEC::Authorization::Voter::Authenticated.new(ASEC::Authentication::TrustResolver.new).vote(token, attribute, vote).should eq expected

    vote.reasons.should eq(reason.nil? ? [] of String : [reason])
  end

  def vote_tests : Hash
    {
      "fully: unsupported"            => {true, "FOO", ASEC::Authorization::Voter::Access::Abstain, nil},
      "fully: IS_AUTHENTICATED_FULLY" => {true, "IS_AUTHENTICATED_FULLY", ASEC::Authorization::Voter::Access::Granted, "The user is fully authenticated."},
      "fully: IS_AUTHENTICATED"       => {true, "IS_AUTHENTICATED", ASEC::Authorization::Voter::Access::Granted, "The user is authenticated."},
      "fully: PUBLIC_ACCESS"          => {true, "PUBLIC_ACCESS", ASEC::Authorization::Voter::Access::Granted, "Access is public."},
      "guest: unsupported"            => {false, "FOO", ASEC::Authorization::Voter::Access::Abstain, nil},
      "guest: IS_AUTHENTICATED_FULLY" => {false, "IS_AUTHENTICATED_FULLY", ASEC::Authorization::Voter::Access::Denied, "The user is not fully authenticated."},
      "guest: IS_AUTHENTICATED"       => {false, "IS_AUTHENTICATED", ASEC::Authorization::Voter::Access::Denied, "The user is not authenticated."},
      "guest: PUBLIC_ACCESS"          => {false, "PUBLIC_ACCESS", ASEC::Authorization::Voter::Access::Granted, "Access is public."},
    }
  end

  @[DataProvider("attributes")]
  def test_supports_attribute(attribute : String, expected : Bool) : Nil
    ASEC::Authorization::Voter::Authenticated.new(ASEC::Authentication::TrustResolver.new).supports_attribute?(attribute).should eq expected
  end

  def attributes : Tuple
    {
      {ASEC::Authorization::Voter::Authenticated::IS_AUTHENTICATED_FULLY, true},
      {ASEC::Authorization::Voter::Authenticated::IS_AUTHENTICATED, true},
      {ASEC::Authorization::Voter::Authenticated::PUBLIC_ACCESS, true},
      {"", false},
      {"foo", false},
    }
  end
end
