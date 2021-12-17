@[ATHA::Prefix("calendar")]
class CalendarController < ATH::Controller
  @[ATHA::Get(path: "events")]
  def events : String
    "events"
  end

  @[ATHA::Get(path: "external")]
  def calendars : String
    "calendars"
  end

  @[ATHA::Get(path: "external/:id")]
  def calendar(id : Int64) : Int64
    id
  end
end

@[ATHA::Prefix(prefix: "/:app_name")]
class CalendarChildController < CalendarController
  @[ATHA::Get(path: "child1")]
  def calendar_app(app_name : String) : String
    "child1 + #{app_name}"
  end
end
