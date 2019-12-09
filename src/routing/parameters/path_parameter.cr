struct Athena::Routing::Parameters::PathParameter(T) < Athena::Routing::Parameters::Parameter(T)
  # :inherit:
  def extract(request : HTTP::Request) : String?
    request.path_params[@name]?
  end

  # :inherit:
  def parameter_type : String
    "path"
  end
end
