# A set of testing utilities/types to aid in testing `Athena::Clock` related types.
#
# ### Getting Started
#
# Require this module in your `spec_helper.cr` file:
#
# ```
# require "athena-clock/spec"
# ```
module Athena::Clock::Spec
  # The mock clock is instantiated with a time and does not move forward on its own.
  # The time is fixed until `#sleep` or `#shift` is called.
  # This provides full control over what time the code assumes it's running with,
  # ultimately making testing time-sensitive types much easier.
  #
  # ```
  # class ExpirationChecker
  #   def initialize(@clock : Athena::Clock::Interface); end
  #
  #   def expired?(valid_until : Time) : Bool
  #     @clock.now > valid_until
  #   end
  # end
  #
  # clock = ACLK::Spec::MockClock.new Time.utc 2023, 9, 16, 15, 20
  # expiration_checker = ExpirationChecker.new clock
  # valid_until = Time.utc 2023, 9, 16, 15, 25
  #
  # # valid_until is in the future, so not expired
  # expiration_checker.expired?(valid_until).should be_false
  #
  # # Sleep for 10 minutes, so time is now 2023-09-16 15:30:00,
  # # time is instantly changes as if 10 minutes really passed
  # clock.sleep 10.minutes
  #
  # expiration_checker.expired?(valid_until).should be_true
  #
  # # Time can also be shifted, either into the future or past
  # clock.shift minutes: -20
  #
  # # valid_until is in the future again, so not expired
  # expiration_checker.expired?(valid_until).should be_false
  # ```
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

    # :inherit:
    def in_location(location : Time::Location) : self
      self.class.new now: Time.local(location)
    end

    # :inherit:
    def now : Time
      @now
    end

    # Shifts the mocked time instance by the provided amount of time.
    # Positive values shift into the future, while negative values shift into the past.
    #
    # This method is essentially equivalent to calling `#sleep` with the same amount of time, but this method provides a better API in some cases.
    def shift(*, years : Int = 0, months : Int = 0, weeks : Int = 0, days : Int = 0, hours : Int = 0, minutes : Int = 0, seconds : Int = 0) : Nil
      @now = @now.shift(years: years, months: months, weeks: weeks, days: days, hours: hours, minutes: minutes, seconds: seconds)
    end

    # :inherit:
    def sleep(span : Time::Span) : Nil
      @now += span
    end
  end

  # An `Athena::Spec::TestCase` mix-in that allows freezing time and restoring the global clock after each test.
  #
  # ```
  # struct MonthSensitiveTest < ASPEC::TestCase
  #   include ACLK::Spec::ClockSensitive
  #
  #   def test_winter_month : Nil
  #     clock = self.mock_time Time.utc 2023, 12, 10
  #
  #     month_sensitive = MonthSensitive.new
  #     month_sensitive.clock = clock
  #
  #     month_sensitive.winter_month?.should be_true
  #   end
  #
  #   def test_non_winter_month : Nil
  #     clock = self.mock_time Time.utc 2023, 7, 10
  #
  #     month_sensitive = MonthSensitive.new
  #     month_sensitive.clock = clock
  #
  #     month_sensitive.winter_month?.should be_false
  #   end
  # end
  # ```
  module ClockSensitive
    @@original_clock : ACLK::Interface? = nil

    # Returns a new clock instanced with the global clock value shifted by the provided amount of time.
    # Positive values shift into the future, while negative values shift into the past.
    def shift(*, years : Int = 0, months : Int = 0, weeks : Int = 0, days : Int = 0, hours : Int = 0, minutes : Int = 0, seconds : Int = 0) : ACLK::Interface
      self.mock_time ACLK.clock.now.shift(years: years, months: months, weeks: weeks, days: days, hours: hours, minutes: minutes, seconds: seconds)
    end

    # Returns clock instance based on the provided *now* value.
    #
    # If a `Time` instance is passed, that value is used.
    # If `true`, freezes the global clock to the current time.
    # If `false`, restores the previous global clock.
    def mock_time(now : Time | Bool = true) : ACLK::Interface
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

    # :nodoc:
    def initialize
      super

      self.save_clock_before_test
    end

    # :inherit:
    protected def tear_down : Nil
      super

      self.restore_clock_after_test
    end
  end
end
