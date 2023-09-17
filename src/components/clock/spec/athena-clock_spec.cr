require "./spec_helper"

struct ClockTest < ASPEC::TestCase
  include ACLK::Spec::ClockSensitive

  def test_supports_mock_clock : Nil
    ACLK.clock.should be_a ACLK::Native

    clock = self.mock_time
    ACLK.clock.should be_a ACLK::Spec::MockClock
    ACLK.clock.should eq clock
  end

  def test_defaults_to_native_clock : Nil
    ACLK.clock.should be_a ACLK::Native
  end

  def test_response_to_mocked_clocks : Nil
    ACLK.clock.should be_a ACLK::Native

    self.mock_time.should be_a ACLK::Spec::MockClock
    self.mock_time(false).should be_a ACLK::Native
  end

  def test_ensure_mock_clock_freezes : Nil
    self.mock_time Time.utc 2023, 9, 16

    ACLK.clock.now.to_s("%F").should eq "2023-09-16"
    ACLK.clock.now.shift(days: 1).to_s("%F").should eq "2023-09-17"

    self.shift days: 1
    ACLK.clock.now.to_s("%F").should eq "2023-09-17"
  end
end
