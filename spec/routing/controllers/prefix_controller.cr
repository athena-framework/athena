@[Athena::Routing::Controller(prefix: "calendar")]
struct CalendarController < Athena::Routing::StructController
  @[Athena::Routing::Get(path: "events")]
  def self.events : String
    "events"
  end

  @[Athena::Routing::Get(path: "external")]
  def self.calendars : String
    "calendars"
  end
end
