# A special parameter that represents a `HTTP::Request` typed controller action argument.
struct Athena::Routing::Parameters::Request(T) < Athena::Routing::Parameters::Parameter(T)
  def extract(request : HTTP::Request) : String?
  end

  # :inherit:
  def parameter_type : String
    "request"
  end
end
