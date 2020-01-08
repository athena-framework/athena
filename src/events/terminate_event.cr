class Athena::Routing::Events::Terminate < AED::Event
  getter request : HTTP::Request
  getter response : HTTP::Server::Response

  def initialize(@request : HTTP::Request, @response : HTTP::Server::Response); end
end
