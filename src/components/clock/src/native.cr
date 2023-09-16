# The default clock for most use cases which returns the current system time.
# For example:
#
# ```
# class ExpirationChecker
#   def initialize(@clock : Athena::Clock::Interface); end
#
#   def expired?(valid_until : Time) : Bool
#     @clock.now > valid_until
#   end
# end
# ```
struct Athena::Clock::Native
  include Athena::Clock::Interface

  @location : Time::Location

  def initialize(
    location : Time::Location? = nil
  )
    @location = location || Time::Location.local
  end

  # :inherit:
  def in_location(location : Time::Location) : self
    self.class.new location: location
  end

  # :inherit:
  def now : Time
    Time.local @location
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
