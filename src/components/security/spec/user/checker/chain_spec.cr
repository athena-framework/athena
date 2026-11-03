require "../../spec_helper"

struct ChainUserCheckerTest < ASPEC::TestCase
  def test_forwards_pre_auth_to_all_user_checkers : Nil
    checkers = {MockUserChecker.new, MockUserChecker.new, MockUserChecker.new}

    ASEC::User::Checker::Chain.new(checkers.to_a.map &.as(ASEC::User::Checker::Interface)).check_pre_auth TestUser.new

    checkers.each &.calls.should eq [{"check_pre_auth", nil}]
  end

  def test_forwards_post_auth_to_all_user_checkers : Nil
    checkers = {MockUserChecker.new, MockUserChecker.new, MockUserChecker.new}
    token = TestToken.new

    ASEC::User::Checker::Chain.new(checkers.to_a.map &.as(ASEC::User::Checker::Interface)).check_post_auth TestUser.new, token

    checkers.each &.calls.should eq [{"check_post_auth", token}]
  end

  def test_stops_at_the_first_rejecting_checker : Nil
    rejecting_checker = MockUserChecker.new ASEC::Exception::Disabled.new "Disabled."
    other_checker = MockUserChecker.new

    expect_raises ASEC::Exception::Disabled do
      ASEC::User::Checker::Chain.new([rejecting_checker, other_checker] of ASEC::User::Checker::Interface).check_pre_auth TestUser.new
    end

    other_checker.calls.should be_empty
  end
end
