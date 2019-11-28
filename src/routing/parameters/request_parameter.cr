# A `HTTP::Request` controller action argument.
struct Athena::Routing::Parameters::RequestParameter(T) < Athena::Routing::Parameters::Parameter(T)
  protected def extract(request : HTTP::Request) : String?
  end

  # Just pass the request thru.
  def parse(request : HTTP::Request) : T
    request
  end
end
