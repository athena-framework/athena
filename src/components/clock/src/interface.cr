# Represents a clock that returns a `Time` instance, possibly in a specific location.
module Athena::Clock::Interface
  # Returns a new clock instance set to the provided *location*.
  abstract def in_location(location : Time::Location) : self

  # Returns the current time as determined by the clock.
  abstract def now : Time

  # Sleeps for the provided *span* of time.
  abstract def sleep(span : Time::Span) : Nil

  # Sleeps for the provided amount of *seconds*.
  abstract def sleep(seconds : Number) : Nil
end
