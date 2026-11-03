require "../../spec_helper"

struct UnanimousStrategyTest < ASPEC::TestCase
  @[DataProvider("strategy_tests")]
  def test_decide(strategy : ASEC::Authorization::Strategy::Interface, voters : Array(ASEC::Authorization::Voter), expected : Bool) : Nil
    ASEC::Authorization::AccessDecisionManager.new(voters, strategy).decide(ASEC::Authentication::Token::Null.new, "ROLE_FOO").should eq expected
  end

  def strategy_tests : Tuple
    strategy = ASEC::Authorization::Strategy::Unanimous.new

    {
      {strategy, access_decision_voters(1, 0, 0), true},
      {strategy, access_decision_voters(1, 0, 1), true},
      {strategy, access_decision_voters(1, 1, 0), false},
      {strategy, access_decision_voters(0, 0, 2), false},
      {ASEC::Authorization::Strategy::Unanimous.new(true), access_decision_voters(0, 0, 2), true},
    }
  end

  def test_to_s : Nil
    ASEC::Authorization::Strategy::Unanimous.new.to_s.should eq "unanimous"
  end
end
