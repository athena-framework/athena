require "./request_event"

class Athena::Routing::Events::Exception < AED::Event
  property exception : ::Exception

  def initialize(@request : HTTP::Request, @exception : ::Exception)
  end
end
