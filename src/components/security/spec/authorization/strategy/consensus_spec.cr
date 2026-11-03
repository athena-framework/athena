require "../../spec_helper"

struct ConsensusStrategyTest < ASPEC::TestCase
  @[DataProvider("strategy_tests")]
  def test_decide(strategy : ASEC::Authorization::Strategy::Interface, voters : Array(ASEC::Authorization::Voter), expected : Bool) : Nil
    ASEC::Authorization::AccessDecisionManager.new(voters, strategy).decide(ASEC::Authentication::Token::Null.new, "ROLE_FOO").should eq expected
  end

  def strategy_tests : Tuple
    strategy = ASEC::Authorization::Strategy::Consensus.new
    strict_strategy = ASEC::Authorization::Strategy::Consensus.new false, false

    {
      {strategy, access_decision_voters(1, 0, 0), true},
      {strategy, access_decision_voters(1, 2, 0), false},
      {strategy, access_decision_voters(2, 1, 0), true},
      {strategy, access_decision_voters(0, 0, 1), false},
      {strategy, access_decision_voters(2, 2, 0), true},
      {strategy, access_decision_voters(2, 2, 1), true},
      {ASEC::Authorization::Strategy::Consensus.new(true), access_decision_voters(0, 0, 1), true},
      {strict_strategy, access_decision_voters(2, 2, 0), false},
      {strict_strategy, access_decision_voters(2, 2, 1), false},
    }
  end

  def test_to_s : Nil
    ASEC::Authorization::Strategy::Consensus.new.to_s.should eq "consensus"
  end
end
