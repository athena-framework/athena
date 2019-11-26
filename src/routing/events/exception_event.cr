require "./request_event"

class Athena::Routing::Events::Exception < Athena::Routing::Events::Request
  getter exception : ::Exception

  def initialize(request : HTTP::Request, @exception : ::Exception)
    super request
  end
end
