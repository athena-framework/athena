struct Athena::Clock::Native
  include Athena::Clock::Interface

  @location : Time::Location

  def initialize(
    location : Time::Location? = nil
  )
    @location = location || Time::Location.local
  end

  def in_location(location : Time::Location) : self
    self.class.new location: location
  end

  def now : Time
    Time.local @location
  end

  def sleep(span : Time::Span) : Nil
    ::sleep span
  end

  def sleep(seconds : Number) : Nil
    ::sleep seconds
  end
end
