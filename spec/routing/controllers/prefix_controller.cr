@[Athena::Routing::ControllerOptions(prefix: "calendar")]
class CalendarController < Athena::Routing::Controller
  @[Athena::Routing::Get(path: "events")]
  def events : String
    "events"
  end

  @[Athena::Routing::Get(path: "external")]
  def calendars : String
    "calendars"
  end

  @[Athena::Routing::Get(path: "external/:id")]
  def calendar(id : Int64) : Int64
    id
  end
end
