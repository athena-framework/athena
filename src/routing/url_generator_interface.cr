module Athena::Routing::URLGeneratorInterface
  enum ReferenceType
    ABSOLUTE_URL
    ABSOLUTE_PATH

    # TODO: Implement this.
    RELATIVE_PATH

    NETWORK_PATH
  end

  abstract def generate(route_name : String, params : Hash(String, _)? = nil, reference_type : ART::URLGeneratorInterface::ReferenceType = :absolute_path) : String
end
