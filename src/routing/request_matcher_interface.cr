module Athena::Routing::RequestMatcherInterface
  # Matches the provided *request* with its related `ART::Action`.
  abstract def match(request : HTTP::Request) : Amber::Router::RoutedResult(Athena::Routing::ActionBase)
end
