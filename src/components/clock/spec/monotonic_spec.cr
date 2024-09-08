require "./spec_helper"

struct MonotonicClockTest < ASPEC::TestCase
  def test_allows_customizing_timezone : Nil
    clock = ACLK::Monotonic.new Time::Location.load "Europe/Berlin"
    clock.now.location.name.should eq "Europe/Berlin"
  end

  def test_defaults_to_local_tz : Nil
    ACLK::Monotonic.new.now.location.local?.should be_true
  end

  def test_now : Nil
    clock = ACLK::Monotonic.new
    before = Time.local.to_unix_ms
    sleep 100.milliseconds
    now = clock.now
    sleep 100.milliseconds
    after = Time.local.to_unix_ms

    now.to_unix_ms.should be > before
    now.to_unix_ms.should be < after
  end

  def test_sleep : Nil
    clock = ACLK::Monotonic.new
    location = clock.now.location

    before = Time.local.to_unix_ms
    clock.sleep 0.5.seconds
    now = clock.now.to_unix_ms
    sleep 100.milliseconds
    after = Time.local.to_unix_ms

    now.should be >= (before + 1.499_999)
    now.should be < after
    clock.now.location.should eq location
  end

  def test_in_location : Nil
    clock = ACLK::Monotonic.new Time::Location.load("America/New_York")
    utc_clock = clock.in_location Time::Location::UTC

    clock.should_not eq utc_clock
    utc_clock.now.location.should eq Time::Location::UTC
  end
end
