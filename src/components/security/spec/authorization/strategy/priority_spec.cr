require "../../spec_helper"

struct PriorityStrategyTest < ASPEC::TestCase
  @[DataProvider("strategy_tests")]
  def test_decide(strategy : ASEC::Authorization::Strategy::Interface, voters : Array(ASEC::Authorization::Voter), expected : Bool) : Nil
    ASEC::Authorization::AccessDecisionManager.new(voters, strategy).decide(ASEC::Authentication::Token::Null.new, "ROLE_FOO").should eq expected
  end

  def strategy_tests : Tuple
    strategy = ASEC::Authorization::Strategy::Priority.new

    {
      {strategy, [MockAttributeVoter.new(:abstain), MockAttributeVoter.new(:granted), MockAttributeVoter.new(:denied), MockAttributeVoter.new(:denied)] of ASEC::Authorization::Voter, true},
      {strategy, [MockAttributeVoter.new(:abstain), MockAttributeVoter.new(:denied), MockAttributeVoter.new(:granted), MockAttributeVoter.new(:granted)] of ASEC::Authorization::Voter, false},
      {strategy, access_decision_voters(0, 0, 2), false},
      {ASEC::Authorization::Strategy::Priority.new(true), access_decision_voters(0, 0, 2), true},
    }
  end

  def test_to_s : Nil
    ASEC::Authorization::Strategy::Priority.new.to_s.should eq "priority"
  end
end
