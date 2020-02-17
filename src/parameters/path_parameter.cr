# Represents a parameter within an action's path such as `id` in the path `"/user/:id"`
struct Athena::Routing::Parameters::Path(T) < Athena::Routing::Parameters::Parameter(T)
  include Athena::Routing::Parameters::Convertable(T)

  def initialize(name : String, @converter : ART::ParamConverterInterface(T)? = nil, default : T? = nil, type : T.class = T)
    super name, default, type
  end

  # :inherit:
  def extract(request : HTTP::Request) : String?
    request.path_params[@name]?
  end

  # :inherit:
  def parameter_type : String
    "path"
  end
end
