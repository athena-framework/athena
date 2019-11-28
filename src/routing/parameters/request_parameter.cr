module Athena::Routing::Parameters
  struct RequestParameter(T) < Parameter(T)
    protected def extract(request : HTTP::Request) : String?
    end

    # Just pass the request thru.
    def parse(request : HTTP::Request) : T
      request
    end
  end
end
