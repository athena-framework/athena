module Athena::Routing::RequestMatcherInterface
  # Matches the provided *request* with its related `ART::Action`.
  abstract def match(request : ART::Request) : Amber::Router::RoutedResult(Athena::Routing::ActionBase)
end
