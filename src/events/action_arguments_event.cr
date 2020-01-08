class Athena::Routing::Events::ActionArguments < AED::Event
  getter request : HTTP::Request

  def initialize(@request : HTTP::Request); end

  def route : ART::Action
    request.route
  end
end
