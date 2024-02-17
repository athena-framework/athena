require "./interface"
require "./native"
require "./monotonic"

# Convenience alias to make referencing `Athena::Clock` types easier.
alias ACLK = Athena::Clock

# The core `Athena::Clock` type can be used to return the current time via a global clock.
#
# ```
# # By default, `Athena::Clock` uses the native clock implementation,
# # but it can be changed to any other implementation
# Athena::Clock.clock = ACLK::Monotonic.new
#
# # Then, obtain a clock instance
# clock = ACLK.clock
#
# # Optionally, with in a specific location
# berlin_clock = clock.in_location Time::Location.load "Europe/Berlin"
#
# # From here, get the current time as a `Time` instance
# now = clock.now # : ::Time
#
# # and sleep for any period of time
# clock.sleep 2
# ```
class Athena::Clock
  include Athena::Clock::Interface

  VERSION = "0.1.1"

  # Represents the global clock used by all `Athena::Clock` instances.
  #
  # NOTE: It is preferable injecting an `Athena::Clock::Interface` when possible versus using the global clock getter.
  class_property clock : ACLK::Interface = ACLK::Native.new

  @clock : ACLK::Interface?
  @location : Time::Location?

  def initialize(
    @clock : ACLK::Interface? = nil,
    @location : Time::Location? = nil
  )
  end

  # :inherit:
  def in_location(location : Time::Location) : self
    self.class.new @clock, location
  end

  # :inherit:
  def now : Time
    now = (@clock || self.class.clock).now

    (location = @location) ? now.in(location) : now
  end

  # :inherit:
  def sleep(span : Time::Span) : Nil
    (@clock || self.class.clock).sleep span
  end

  # :inherit:
  def sleep(seconds : Number) : Nil
    (@clock || self.class.clock).sleep seconds
  end
end
