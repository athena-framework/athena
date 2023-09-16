module Athena::Clock::Spec
  class MockClock
    include Athena::Clock::Interface

    @now : Time
    @location : Time::Location

    def initialize(
      now : Time = Time.local,
      location : Time::Location? = nil
    )
      @location = location || Time::Location::UTC
      @now = now.in @location
    end

    def in_location(location : Time::Location) : self
      self.class.new now: Time.local(location)
    end

    def now : Time
      @now
    end

    def shift(*, years : Int = 0, months : Int = 0, weeks : Int = 0, days : Int = 0, hours : Int = 0, minutes : Int = 0, seconds : Int = 0) : Nil
      @now = @now.shift(years: years, months: months, weeks: weeks, days: days, hours: hours, minutes: minutes, seconds: seconds)
    end

    def sleep(span : Time::Span) : Nil
      @now += span
    end

    def sleep(seconds : Number) : Nil
      self.sleep seconds.seconds
    end
  end

  module ClockSensitive
    @@original_clock : ACLK::Interface? = nil

    def mock_time(*, years : Int = 0, months : Int = 0, weeks : Int = 0, days : Int = 0, hours : Int = 0, minutes : Int = 0, seconds : Int = 0)
      self.mock_time ACLK.clock.now.shift(years: years, months: months, weeks: weeks, days: days, hours: hours, minutes: minutes, seconds: seconds)
    end

    def mock_time(now : Time | Bool = true) : Athena::Clock::Interface
      ACLK.clock = case now
                   in false then self.save_clock_before_test false
                   in true  then ACLK::Spec::MockClock.new
                   in Time  then ACLK::Spec::MockClock.new now
                   end

      Athena::Clock.clock
    end

    protected def save_clock_before_test(save : Bool = true) : ACLK::Interface
      save ? (@@original_clock = ACLK.clock) : @@original_clock.not_nil!
    end

    protected def restore_clock_after_test : Nil
      ACLK.clock = self.save_clock_before_test false
    end

    def initialize
      super

      self.save_clock_before_test
    end

    protected def tear_down : Nil
      super

      self.restore_clock_after_test
    end
  end
end
