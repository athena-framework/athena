# A `HTTP::Request` controller action argument.
struct Athena::Routing::Parameters::ResponseParameter(T) < Athena::Routing::Parameters::Parameter(T)
  def extract(request : HTTP::Request) : String?
  end

  # :inherit:
  def parameter_type : String
    "response"
  end
end
