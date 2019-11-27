module Athena::Routing::Parameters
  struct PathParameter(T) < Parameter(T)
    # :inherit:
    protected def extract(request : HTTP::Request) : String?
      request.path_params[@name]?
    end
  end
end
