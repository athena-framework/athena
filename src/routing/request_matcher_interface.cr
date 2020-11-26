module Athena::Routing::RequestMatcherInterface
  abstract def match(request : HTTP::Request) : Amber::Router::RoutedResult(Athena::Routing::ActionBase)
end
