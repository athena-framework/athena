require "../spec_helper"

struct AuthorizationCheckerTest < ASPEC::TestCase
  @token_storage : ASEC::Authentication::Token::Storage
  @voter : MockAttributeVoter

  def initialize
    @token_storage = ASEC::Authentication::Token::Storage.new
    @voter = MockAttributeVoter.new
  end

  def test_without_token : Nil
    self.checker.granted?("ROLE_FOO").should be_true

    @voter.calls.first[0].should be_a ASEC::Authentication::Token::Null
  end

  def test_token_without_user : Nil
    @token_storage.token = TestToken.new ["ROLE_FOO"]

    self.checker.granted?("ROLE_FOO").should be_true

    @voter.calls.first[0].should be_a ASEC::Authentication::Token::Null
  end

  @[DataProvider("results")]
  def test_granted(result : ASEC::Authorization::Voter::Access, expected : Bool) : Nil
    token = ASEC::Authentication::Token::UsernamePassword.new ASEC::User::InMemory.new("username", "password", ["ROLE_USER"]), "provider", ["ROLE_USER"]
    @token_storage.token = token
    @voter = MockAttributeVoter.new result

    self.checker.granted?("ROLE_FOO").should eq expected

    @voter.calls.should eq [{token, "ROLE_FOO"}]
  end

  def results : Tuple
    {
      {ASEC::Authorization::Voter::Access::Granted, true},
      {ASEC::Authorization::Voter::Access::Denied, false},
    }
  end

  def test_granted_with_subject : Nil
    @token_storage.token = TestToken.new user: TestUser.new("author")

    checker = ASEC::Authorization::Checker.new @token_storage, ASEC::Authorization::AccessDecisionManager.new([PostVoter.new] of ASEC::Authorization::Voter)

    checker.granted?("EDIT", Post.new("author")).should be_true
    checker.granted?("EDIT", Post.new("other")).should be_false
  end

  def test_records_the_decision : Nil
    access_decision = ASEC::Authorization::AccessDecision.new

    self.checker.granted?("ROLE_FOO", access_decision: access_decision).should be_true

    access_decision.granted?.should be_true
    access_decision.votes.size.should eq 1
  end

  def test_nested_check_shares_the_ongoing_access_decision : Nil
    access_decision = ASEC::Authorization::AccessDecision.new
    checker = uninitialized ASEC::Authorization::Checker
    voters = [
      NestedDecisionVoter.new(-> { checker.granted? "ROLE_NESTED" }),
      MockAttributeVoter.new(:granted, supported_attributes: ["ROLE_NESTED"]),
    ] of ASEC::Authorization::Voter

    checker = ASEC::Authorization::Checker.new @token_storage, ASEC::Authorization::AccessDecisionManager.new(voters)

    checker.granted?("ROLE_FOO", access_decision: access_decision).should be_true

    access_decision.votes.map(&.voter).should eq ["MockAttributeVoter", "NestedDecisionVoter"]
  end

  private def checker : ASEC::Authorization::Checker
    ASEC::Authorization::Checker.new @token_storage, ASEC::Authorization::AccessDecisionManager.new([@voter] of ASEC::Authorization::Voter)
  end
end
