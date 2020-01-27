require "./request_aware"

class Athena::Routing::Events::View < AED::Event
  include Athena::Routing::Events::RequestAware

  getter view : ViewBase

  # The response object.
  getter response : ART::Response? = nil

  def initialize(request : HTTP::Request, @view : ViewBase)
    super request
  end

  def response=(@response : ART::Response) : Nil
    stop_propagation
  end
end
