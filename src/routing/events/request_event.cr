class Athena::Routing::Events::Request < AED::Event
  getter request : HTTP::Request

  def initialize(@request : HTTP::Request); end
end
