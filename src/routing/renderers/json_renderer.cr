require "./renderer"

module Athena::Routing::Renderers
  # Serializes `T` as `JSON`, and sets the response's *Content-Type* header.
  struct JSONRenderer < Renderer
    def render(response : T, groups : Array(String) = [] of String) : String forall T
      @request_stack.response.content_type = "application/json; charset=utf-8"
      response.to_json groups
    end
  end
end
