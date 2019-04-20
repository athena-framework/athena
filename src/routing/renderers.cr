module Athena::Routing::Renderers
  # Serializes `T` as `JSON`, and sets the response's *Content-Type* header.
  struct JSONRenderer
    def self.render(response : T, ctx : HTTP::Server::Context, groups : Array(String) = [] of String) : String forall T
      ctx.response.content_type = "application/json; charset=utf-8"
      response.to_json groups
    end
  end

  # Serializes `T` as `YAML`, and sets the response's *Content-Type* header.
  struct YAMLRenderer
    def self.render(response : T, ctx : HTTP::Server::Context, groups : Array(String) = [] of String) : String forall T
      ctx.response.content_type = "text/x-yaml; charset=utf-8"
      response.to_yaml groups
    end
  end

  # Render's `T` ECR file, sets the response's *Content-Type* header to `text/html`.
  struct ECRRenderer
    def self.render(response : T, ctx : HTTP::Server::Context, groups : Array(String) = [] of String) : String forall T
      ctx.response.content_type = "text/html; charset=utf-8"
      response.to_s
    end
  end
end
