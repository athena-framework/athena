require "./renderer"

module Athena::Routing::Renderers
  # Render's `T` ECR file, sets the response's *Content-Type* header to `text/html`.
  struct ECRRenderer < Renderer
    def render(response : T, groups : Array(String) = [] of String) : String forall T
      @request_stack.response.content_type = "text/html; charset=utf-8"
      response.to_s
    end
  end
end
