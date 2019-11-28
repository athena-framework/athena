# require "./parameter"

module Athena::Routing::Parameters
  struct QueryParameter(T) < Parameter(T)
    # :inherit:
    def extract(request : HTTP::Request) : String?
      request.query_params[@name]?
    end
  end
end
