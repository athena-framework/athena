require "./interface"
require "./native"
require "./monotonic"

# Convenience alias to make referencing `Athena::Clock` types easier.
alias ACLK = Athena::Clock

class Athena::Clock
  include Athena::Clock::Interface

  VERSION = "0.1.0"

  class_property clock : ACLK::Interface = ACLK::Native.new

  @clock : ACLK::Interface?
  @location : Time::Location?

  def initialize(
    @clock : ACLK::Interface? = nil,
    @location : Time::Location? = nil
  )
  end

  def in_location(location : Time::Location) : self
    self.class.new @clock, location
  end

  def now : Time
    now = (@clock || self.class.clock).now

    (location = @location) ? now.in(location) : now
  end

  def sleep(span : Time::Span) : Nil
    (@clock || self.class.clock).sleep span
  end

  def sleep(seconds : Number) : Nil
    (@clock || self.class.clock).sleep seconds
  end
end
