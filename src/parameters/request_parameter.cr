# A special parameter that represents a `HTTP::Request` typed controller action argument.
struct Athena::Routing::Parameters::RequestParameter(T) < Athena::Routing::Parameters::Parameter(T)
  def extract(request : HTTP::Request) : String?
  end

  # :inherit:
  def parameter_type : String
    "request"
  end
end
