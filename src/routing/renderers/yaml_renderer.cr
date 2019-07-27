require "./renderer"

module Athena::Routing::Renderers
  # Serializes `T` as `YAML`, and sets the response's *Content-Type* header.
  struct YAMLRenderer < Renderer
    def render(response : T, groups : Array(String) = [] of String) : String forall T
      @request_stack.response.content_type = "text/x-yaml; charset=utf-8"
      response.to_yaml groups
    end
  end
end
