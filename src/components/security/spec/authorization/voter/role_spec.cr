require "../../spec_helper"

struct RoleVoterTest < ASPEC::TestCase
  @[DataProvider("vote_tests")]
  def test_vote(roles : Array(String), attribute : String, expected : ASEC::Authorization::Voter::Access) : Nil
    ASEC::Authorization::Voter::Role.new.vote(TestToken.new(roles), attribute).should eq expected
  end

  def vote_tests : Tuple
    {
      {[] of String, "FOO", ASEC::Authorization::Voter::Access::Abstain},
      {[] of String, "ROLE_FOO", ASEC::Authorization::Voter::Access::Denied},
      {["ROLE_FOO"], "ROLE_FOO", ASEC::Authorization::Voter::Access::Granted},
      {["ROLE_BAR", "ROLE_FOO"], "ROLE_FOO", ASEC::Authorization::Voter::Access::Granted},
      {["ROLE_FOO"], "ROLE_BAR", ASEC::Authorization::Voter::Access::Denied},
    }
  end

  def test_vote_reasons : Nil
    voter = ASEC::Authorization::Voter::Role.new

    vote = ASEC::Authorization::Voter::Vote.new
    voter.vote TestToken.new(["ROLE_FOO"]), "ROLE_FOO", vote
    vote.reasons.should eq ["The user has ROLE_FOO."]

    vote = ASEC::Authorization::Voter::Vote.new
    voter.vote TestToken.new, "ROLE_FOO", vote
    vote.reasons.should eq ["The user doesn't have ROLE_FOO."]
  end

  def test_custom_prefix : Nil
    voter = ASEC::Authorization::Voter::Role.new "GROUP_"

    voter.vote(TestToken.new(["GROUP_FOO"]), "GROUP_FOO").should eq ASEC::Authorization::Voter::Access::Granted
    voter.vote(TestToken.new(["ROLE_FOO"]), "ROLE_FOO").should eq ASEC::Authorization::Voter::Access::Abstain
  end

  @[DataProvider("attributes")]
  def test_supports_attribute(prefix : String, attribute : String, expected : Bool) : Nil
    ASEC::Authorization::Voter::Role.new(prefix).supports_attribute?(attribute).should eq expected
  end

  def attributes : Tuple
    {
      {"ROLE_", "ROLE_foo", true},
      {"ROLE_", "ROLE_", true},
      {"FOO_", "FOO_bar", true},
      {"ROLE_", "", false},
      {"ROLE_", "foo", false},
    }
  end
end
