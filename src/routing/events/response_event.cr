class Athena::Routing::Events::Response < AED::Event
  getter response : HTTP::Server::Response

  def initialize(@response : HTTP::Server::Response); end
end
