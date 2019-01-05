module Athena::Renderers
  class JSONRenderer(T)
    def self.render(response : T, action : Action, context : HTTP::Server::Context) : String forall T
      context.response.headers.add "Content-Type", "application/json"
      response.responds_to?(:serialize) ? response.serialize(action.groups) : response.to_json
    end
  end

  class YAMLRenderer(T)
    def self.render(response : T, action : Action, context : HTTP::Server::Context) : String forall T
      context.response.headers.add "Content-Type", "text/x-yaml"
      response.to_yaml
    end
  end

  class ECRRenderer(T)
    def self.render(response : T, action : Action, context : HTTP::Server::Context) : String forall T
      context.response.headers.add "Content-Type", "text/html"
      response.to_s
    end
  end
end
