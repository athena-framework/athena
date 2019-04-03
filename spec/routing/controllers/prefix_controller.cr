@[Athena::Routing::ControllerOptions(prefix: "calendar")]
struct CalendarController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "events")]
  def self.events : String
    "events"
  end

  @[Athena::Routing::Get(path: "external")]
  def self.calendars : String
    "calendars"
  end

  @[Athena::Routing::Get(path: "external/:id")]
  def self.calendar(id : Int64) : Int64
    id
  end
end
