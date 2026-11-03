require "../../spec_helper"

struct AffirmativeStrategyTest < ASPEC::TestCase
  @[DataProvider("strategy_tests")]
  def test_decide(strategy : ASEC::Authorization::Strategy::Interface, voters : Array(ASEC::Authorization::Voter), expected : Bool) : Nil
    ASEC::Authorization::AccessDecisionManager.new(voters, strategy).decide(ASEC::Authentication::Token::Null.new, "ROLE_FOO").should eq expected
  end

  def strategy_tests : Tuple
    strategy = ASEC::Authorization::Strategy::Affirmative.new

    {
      {strategy, access_decision_voters(1, 0, 0), true},
      {strategy, access_decision_voters(1, 2, 0), true},
      {strategy, access_decision_voters(0, 1, 0), false},
      {strategy, access_decision_voters(0, 0, 1), false},
      {ASEC::Authorization::Strategy::Affirmative.new(true), access_decision_voters(0, 0, 1), true},
    }
  end

  def test_to_s : Nil
    ASEC::Authorization::Strategy::Affirmative.new.to_s.should eq "affirmative"
  end
end
