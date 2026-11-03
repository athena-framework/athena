require "../../spec_helper"

struct RoleHierarchyVoterTest < ASPEC::TestCase
  @[DataProvider("vote_tests")]
  def test_vote(roles : Array(String), attribute : String, expected : ASEC::Authorization::Voter::Access) : Nil
    voter = ASEC::Authorization::Voter::RoleHierarchy.new ASEC::Role::Hierarchy.new({
      "ROLE_FOO"   => ["ROLE_FOOBAR"],
      "ROLE_FOO_*" => ["ROLE_BAR_A", "ROLE_FOO"],
      "ROLE_BAR_*" => ["ROLE_BAZ"],
    })

    voter.vote(TestToken.new(roles), attribute).should eq expected
  end

  def vote_tests : Hash
    {
      "not a role"                                                       => {[] of String, "FOO", ASEC::Authorization::Voter::Access::Abstain},
      "missing role"                                                     => {[] of String, "ROLE_FOO", ASEC::Authorization::Voter::Access::Denied},
      "role"                                                             => {["ROLE_FOO"], "ROLE_FOO", ASEC::Authorization::Voter::Access::Granted},
      "child role"                                                       => {["ROLE_FOO"], "ROLE_FOOBAR", ASEC::Authorization::Voter::Access::Granted},
      "ROLE_FOO_A => ROLE_FOO_* => ROLE_BAR_A"                           => {["ROLE_FOO_A"], "ROLE_BAR_A", ASEC::Authorization::Voter::Access::Granted},
      "ROLE_FOO_A => ROLE_FOO_* => ROLE_FOO => ROLE_FOOBAR"              => {["ROLE_FOO_A"], "ROLE_FOOBAR", ASEC::Authorization::Voter::Access::Granted},
      "ROLE_FOO_A => ROLE_FOO_* => ROLE_BAR_A => ROLE_BAR_* => ROLE_BAZ" => {["ROLE_FOO_A"], "ROLE_BAZ", ASEC::Authorization::Voter::Access::Granted},
    }
  end

  def test_vote_with_empty_hierarchy : Nil
    voter = ASEC::Authorization::Voter::RoleHierarchy.new ASEC::Role::Hierarchy.new({} of String => Array(String))

    voter.vote(TestToken.new(["ROLE_FOO"]), "ROLE_FOO").should eq ASEC::Authorization::Voter::Access::Granted
    voter.vote(TestToken.new(["ROLE_FOO"]), "ROLE_BAR").should eq ASEC::Authorization::Voter::Access::Denied
  end

  def test_custom_prefix : Nil
    voter = ASEC::Authorization::Voter::RoleHierarchy.new ASEC::Role::Hierarchy.new({"GROUP_A" => ["GROUP_B"]}), "GROUP_"

    voter.vote(TestToken.new(["GROUP_A"]), "GROUP_B").should eq ASEC::Authorization::Voter::Access::Granted
  end
end
