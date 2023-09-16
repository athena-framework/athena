struct Athena::Clock::Monotonic
  include Athena::Clock::Interface

  @location : Time::Location
  @nanosecond_offset : Int128

  def initialize(
    location : Time::Location? = nil
  )
    @location = location || Time::Location.local
    @nanosecond_offset = Time.utc.to_unix_ns - Time.monotonic.total_nanoseconds.to_i128
  end

  def in_location(location : Time::Location) : self
    self.class.new location: location
  end

  def now : Time
    Time.unix_ns(Time.monotonic.total_nanoseconds.to_i128 + @nanosecond_offset).in @location
  end

  def sleep(span : Time::Span) : Nil
    ::sleep span
  end

  def sleep(seconds : Number) : Nil
    ::sleep seconds
  end
end
