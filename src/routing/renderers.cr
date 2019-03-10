module Athena::Routing::Renderers
  # Serializes `T` as `JSON`, and sets the response's *Content-Type* header.
  struct JSONRenderer
    def self.render(response : T, ctx : HTTP::Server::Context, groups : Array(String) = [] of String) : String forall T
      ctx.response.headers.add "Content-Type", "application/json"
      response.to_json groups
    end
  end

  # Serializes `T` as `YAML`, and sets the response's *Content-Type* header.
  struct YAMLRenderer
    def self.render(response : T, ctx : HTTP::Server::Context, groups : Array(String) = [] of String) : String forall T
      ctx.response.headers.add "Content-Type", "text/x-yaml"
      response.to_yaml groups
    end
  end

  # Render's `T` ECR file, sets the response's *Content-Type* header to `text/html`.
  struct ECRRenderer
    def self.render(response : T, ctx : HTTP::Server::Context, groups : Array(String) = [] of String) : String forall T
      ctx.response.headers.add "Content-Type", "text/html"
      response.to_s
    end
  end
end
