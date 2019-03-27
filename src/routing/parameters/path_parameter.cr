module Athena::Routing::Parameters
  struct PathParameter(T) < Parameter(T)
    getter segment_index : Int32

    def initialize(name : String, @segment_index : Int32)
      super name
    end

    def process(ctx : HTTP::Server::Context) : String?
      # If the query param was defined.
      ctx.request.path.split('/')[@segment_index]
    end
  end
end
