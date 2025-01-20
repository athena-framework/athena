require "./spec_helper"

private class Example
  include Athena::Clock::Aware
end

struct AwareTest < ASPEC::TestCase
  def test_happy_path : Nil
    instance = Example.new
    instance.now.should_not be_nil
    instance.clock = ACLK::Spec::MockClock.new Time.utc 2023, 9, 16, 23, 53, 0
    instance.now.should eq Time.utc(2023, 9, 16, 23, 53, 0)
  end
end
