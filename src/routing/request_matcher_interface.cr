module Athena::Routing::RequestMatcherInterface
  # Matches the provided *request* with its related `ATH::Action`.
  abstract def match(request : ATH::Request) : Amber::Router::RoutedResult(Athena::Framework::ActionBase)
end
