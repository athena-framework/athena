@[Athena::Routing::ControllerOptions(prefix: "calendar")]
abstract struct CalendarController < Athena::Routing::Controller
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

@[Athena::Routing::ControllerOptions(prefix: "/:app_name")]
struct CalendarChildController < CalendarController
  @[Athena::Routing::Get(path: "child1")]
  def calendar_app(app_name : String) : String
    "child1 + #{app_name}"
  end
end
