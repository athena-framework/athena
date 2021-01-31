# Default implementation of `ART::URLGeneratorInterface`.
class Athena::Routing::URLGenerator
  include Athena::Routing::URLGeneratorInterface

  def initialize(
    @routes : ART::RouteCollection,
    @request : HTTP::Request,
    @base_uri : URI?
  ); end

  # :inherit:
  #
  # *params* are validated to ensure they are all provided, and meet any route constraints defined on the action.
  #
  # OPTIMIZE: Make URL generation more robust.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  def generate(route : String, params : Hash(String, _)? = nil, reference_type : ART::URLGeneratorInterface::ReferenceType = :absolute_path) : String
    route = @routes.get route

    fragment = params.try &.delete("_fragment").to_s.presence

    # Create a hash of params based on passed in params object as well as route argument defaults.
    merged_params = route.arguments.to_h do |argument|
      if !argument.has_default? && !argument.nilable? && !params.try(&.has_key?(argument.name))
        raise ArgumentError.new "Route argument '#{argument.name}' is not nilable and was not provided nor has a default value."
      end

      # Cast the value to a string since everything is going to be a string anyway; avoids a compiler type error :shrug:.
      value = if !params.try &.has_key? argument.name
                argument.default
              else
                params_value = params.try &.[argument.name]
                raise ArgumentError.new "Route argument '#{argument.name}' is not nilable." if params_value.nil? && !argument.nilable? && argument.default.nil?
                params_value
              end.to_s

      # Validate the param matches any route constraints for that param defined on the route.
      if requirements = route.constraints[argument.name]?
        raise ArgumentError.new "Route argument '#{argument.name}' for route '#{route.name}' must match '#{requirements}', got '#{value}'." unless value.matches? requirements
      end

      # Skip params whose value isn't the same as the default,
      # Allows the value to be added as query params.
      if (param = route.params.find(&.name.==(argument.name))) && (param.default.to_s != value)
        next {"", ""}
      end

      params.try &.delete argument.name

      {":#{argument.name}", value}
    end

    # Use any extra passed in params as query params.
    query = if params && !(params.compact!).empty?
              HTTP::Params.encode params.transform_values &.to_s.as(String)
            end

    # Use the base_uri parameter if defined.
    base_uri = if buri = @base_uri
                 # Use a copy of it as to not mutate the original.
                 buri.dup
               elsif (host = @request.hostname)
                 # Only bother setting the port if the `port` value can be extracted from the `host` header, and is no a standard port.
                 if (host_header = @request.headers["host"]?) && (p = host_header.partition(':').last) && !p.in?("", "80", "443")
                   port = p.to_i
                 end
                 URI.new scheme: "https", host: host, port: port
               else
                 # Fallback to an absolute path if no hostname could be resolved.
                 URI.new
               end

    path = route.path.gsub(/(?:(:\w+))/, merged_params).gsub(/\/+$/, "")

    case reference_type
    in .absolute_path? then base_uri = URI.new path: base_uri.path
    in .absolute_url? # skip
    in .relative_path? then raise NotImplementedError.new("Relative path reference type is currently not supported.")
    in .network_path?  then base_uri.scheme = nil
    end

    base_uri.tap do |uri|
      uri.path = Path.posix(uri.path).join(path).to_s
      uri.query = query
      uri.fragment = fragment
    end.to_s
  end
end
