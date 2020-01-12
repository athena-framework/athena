@[ART::Prefix("calendar")]
class CalendarController < ART::Controller
  @[Athena::Routing::Get(path: "events")]
  def events : String
    "events"
  end

  @[ART::Get(path: "external")]
  def calendars : String
    "calendars"
  end

  @[ART::Get(path: "external/:id")]
  def calendar(id : Int64) : Int64
    id
  end
end

@[ART::Prefix(prefix: "/:app_name")]
class CalendarChildController < CalendarController
  @[ART::Get(path: "child1")]
  def calendar_app(app_name : String) : String
    "child1 + #{app_name}"
  end
end
