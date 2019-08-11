module Athena::Routing::Renderers
  # Base struct of renderers.
  abstract struct Renderer
    include Athena::DI::Injectable

    protected def initialize(@request_stack : Athena::Routing::RequestStack); end

    # Renders the given input into another format for the response.
    abstract def render(response : T, groups : Array(String) = [] of String) : String forall T
  end
end
