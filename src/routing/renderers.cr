module Athena::Routing::Renderers
  # Serializes `T` as `JSON`, and sets the response's *Content-Type* header.
  struct JSONRenderer(T)
    def self.render(response : T, action : Action, context : HTTP::Server::Context) : String forall T
      context.response.headers.add "Content-Type", "application/json"
      response.to_json action.groups
    end
  end

  # Serializes `T` as `YAML`, and sets the response's *Content-Type* header.
  struct YAMLRenderer(T)
    def self.render(response : T, action : Action, context : HTTP::Server::Context) : String forall T
      context.response.headers.add "Content-Type", "text/x-yaml"
      response.to_yaml action.groups
    end
  end

  # Render's `T` ECR file, sets the response's *Content-Type* header to `text/html`.
  struct ECRRenderer(T)
    def self.render(response : T, action : Action, context : HTTP::Server::Context) : String forall T
      context.response.headers.add "Content-Type", "text/html"
      response.to_s
    end
  end
end
