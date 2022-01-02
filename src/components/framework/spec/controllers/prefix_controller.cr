@[ARTA::Route(path: "calendar")]
class CalendarController < ATH::Controller
  @[ARTA::Get(path: "events")]
  def events : String
    "events"
  end

  @[ARTA::Get(path: "external")]
  def calendars : String
    "calendars"
  end

  @[ARTA::Get(path: "external/{id}")]
  def calendar(id : Int64) : Int64
    id
  end
end

@[ARTA::Route(path: "/{app_name}")]
class CalendarChildController < CalendarController
  @[ARTA::Get(path: "child1")]
  def calendar_app(app_name : String) : String
    "child1 + #{app_name}"
  end
end
