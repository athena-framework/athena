struct Athena::Routing::Parameters::PathParameter(T) < Athena::Routing::Parameters::Parameter(T)
  # :inherit:
  protected def extract(request : HTTP::Request) : String?
    request.path_params[@name]?
  end

  # :inherit:
  protected def type : String
    "path"
  end
end
