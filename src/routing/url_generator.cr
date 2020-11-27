class Athena::Routing::URLGenerator
  include Athena::Routing::URLGeneratorInterface

  def initialize(@routes : ART::RouteCollection, @request : HTTP::Request); end

  def generate(route_name : String, params : Hash(String, _)? = nil, reference_type : ART::URLGeneratorInterface::ReferenceType = :absolute_path) : String
    route = @routes.get route_name

    fragment = params.delete("_fragment").to_s.presence

    # Create a hash of params based on passed in params object as well as route argument defaults.
    merged_params = route.arguments.to_h do |argument|
      if !argument.has_default? && !argument.nilable? && !params.try &.has_key? argument.name
        raise "Missing required param"
      end

      value = if !params.try &.has_key? argument.name
                argument.default
              else
                params.try &.delete argument.name
              end

      {":#{argument.name}", value}
    end

    # Use any extra passed in params as query params.
    query = if params && !params.empty?
              HTTP::Params.encode params.transform_values &.to_s
            end

    uri = URI.new(
      scheme: "https", # TODO: Should this be configurable in some way?
      host: @request.host,
      port: (@request.host_with_port.try &.split(':').last?.try &.to_i),
      path: route.path.gsub(/(?:(:\w+))/, merged_params),
      query: query,
      fragment: fragment
    )

    case reference_type
    in .absolute_path? then uri.full_path
    in .absolute_url?  then uri.to_s
    in .relative_path? then ""
    in .network_path?  then ""
    end
  end
end
