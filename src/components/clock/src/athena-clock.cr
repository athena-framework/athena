require "./aware"
require "./interface"
require "./native"
require "./monotonic"

# Convenience alias to make referencing `Athena::Clock` types easier.
alias ACLK = Athena::Clock

# Decouples applications from the system clock.
class Athena::Clock
  include Athena::Clock::Interface

  VERSION = "0.1.2"

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
end
