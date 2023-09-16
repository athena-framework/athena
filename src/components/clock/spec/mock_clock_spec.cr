require "./spec_helper"

struct MockClockTest < ASPEC::TestCase
  def test_allows_customizing_timezone : Nil
    clock = ACLK::Spec::MockClock.new location: Time::Location.load "Europe/Berlin"
    clock.now.location.name.should eq "Europe/Berlin"
  end

  def test_defaults_to_utc : Nil
    ACLK::Spec::MockClock.new.now.location.utc?.should be_true
  end

  def test_allows_specifying_a_specific_time : Nil
    ACLK::Spec::MockClock.new(now = Time.local).now.should eq now
  end

  def test_now : Nil
    before = Time.utc.to_unix_ms
    sleep 10.milliseconds
    clock = ACLK::Spec::MockClock.new
    sleep 10.milliseconds
    now = clock.now
    after = Time.utc.to_unix_ms

    now.to_unix_ms.should be > before
    now.to_unix_ms.should be < after
    clock.now.should eq clock.now
  end

  def test_sleep : Nil
    clock = ACLK::Spec::MockClock.new Time.utc 2023, 9, 16, 23, 53, 0, nanosecond: 999_000_000
    location = clock.now.location

    clock.sleep 2.002_001
    clock.now.to_s("%F %H:%M:%S.%6N").should eq "2023-09-16 23:53:03.001001"
    clock.now.location.should eq location
  end

  def test_shift : Nil
    clock = ACLK::Spec::MockClock.new Time.utc 2023, 9, 16, 23, 53, 0

    clock.shift days: 2, seconds: 12, hours: -1

    clock.now.to_s("%F %H:%M:%S").should eq "2023-09-18 22:53:12"
  end

  def test_in_location : Nil
    clock = ACLK::Spec::MockClock.new location: Time::Location.load("America/New_York")
    utc_clock = clock.in_location Time::Location::UTC

    clock.should_not eq utc_clock
    utc_clock.now.location.should eq Time::Location::UTC
  end
end
