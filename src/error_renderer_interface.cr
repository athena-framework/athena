module Athena::Routing::ErrorRendererInterface
  abstract def render(exception : ::Exception) : ART::Response
end
