class Athena::Routing::Events::ActionArguments < AED::Event
  getter request : HTTP::Request

  def initialize(@request : HTTP::Request); end
end
