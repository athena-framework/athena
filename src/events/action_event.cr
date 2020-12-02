require "./request_aware"

# Emitted after `ART::Events::Request` and the related `ART::Action` has been resolved, but before it has been executed.
class Athena::Routing::Events::Action < AED::Event
  include Athena::Routing::Events::RequestAware

  # The related `ART::Action` that will be used to handle the current request.
  getter action : ART::ActionBase

  def initialize(request : HTTP::Request, @action : ART::ActionBase)
    super request
  end
end
