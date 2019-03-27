module Athena::Routing::Parameters
  abstract struct Param; end

  abstract struct Parameter(T) < Param
    getter name : String

    def initialize(@name : String, @type : T.class = T); end

    abstract def process(ctx : HTTP::Server::Context) : String?

    def required? : Bool
      !@type.nilable?
    end
  end
end
