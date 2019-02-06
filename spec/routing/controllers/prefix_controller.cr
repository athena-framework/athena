@[Athena::Routing::Controller(prefix: "calendar")]
class CalendarController < Athena::Routing::ClassController
  @[Athena::Routing::Get(path: "events")]
  def self.events : String
    "events"
  end

  @[Athena::Routing::Get(path: "external")]
  def self.calendars : String
    "calendars"
  end
end
