# The monotonic clock is primarily intended to be use to measure time, such as for a stopwatch.
# It's measurements are unaffected by inconsistencies sometimes introduced by the system clock.
# See [Measuring Time](https://crystal-lang.org/api/Time.html#measuring-time) for more information.
class Athena::Clock::Monotonic
  include Athena::Clock::Interface

  @location : Time::Location
  @nanosecond_offset : Int128

  def initialize(
    location : Time::Location? = nil
  )
    @location = location || Time::Location.local
    @nanosecond_offset = Time.utc.to_unix_ns - Time.monotonic.total_nanoseconds.to_i128
  end

  # :inherit:
  def in_location(location : Time::Location) : self
    self.class.new location: location
  end

  # :inherit:
  def now : Time
    Time.unix_ns(Time.monotonic.total_nanoseconds.to_i128 + @nanosecond_offset).in @location
  end

  # :inherit:
  def sleep(span : Time::Span) : Nil
    ::sleep span
  end

  # :inherit:
  def sleep(seconds : Number) : Nil
    ::sleep seconds
  end
end
