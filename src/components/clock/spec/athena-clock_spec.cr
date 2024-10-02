require "./spec_helper"

struct ClockTest < ASPEC::TestCase
  include ACLK::Spec::ClockSensitive

  def test_functions_as_a_clock : Nil
    self.mock_time Time.utc 2023, 9, 16

    clock = ACLK.new

    clock.now.to_s("%F").should eq "2023-09-16"
  end

  def test_accepts_an_existing_clock : Nil
    clock = ACLK.new ACLK::Spec::MockClock.new Time.utc 2023, 9, 16, 23, 53, 0
    clock.now.to_s("%F").should eq "2023-09-16"
  end

  def test_in_location : Nil
    clock = ACLK.new location: Time::Location.load("America/New_York")
    utc_clock = clock.in_location Time::Location::UTC

    clock.should_not eq utc_clock
    utc_clock.now.location.should eq Time::Location::UTC
  end

  def test_sleep : Nil
    clock = ACLK.new ACLK::Spec::MockClock.new Time.utc 2023, 9, 16, 23, 53, 0, nanosecond: 999_000_000
    location = clock.now.location

    clock.sleep 2.002_001.seconds
    clock.now.to_s("%F %H:%M:%S.%6N").should eq "2023-09-16 23:53:03.001001"
    clock.now.location.should eq location
  end

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
