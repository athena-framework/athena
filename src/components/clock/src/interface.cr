class Athena::Clock; end

module Athena::Clock::Interface
  abstract def in_location(location : Time::Location) : self
  abstract def now : Time
  abstract def sleep(span : Time::Span) : Nil
  abstract def sleep(seconds : Number) : Nil
end
