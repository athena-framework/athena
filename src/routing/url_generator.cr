# Default implementation of `ART::URLGeneratorInterface`.
class Athena::Routing::URLGenerator
  include Athena::Routing::URLGeneratorInterface

  def initialize(
    @routes : ART::RouteCollection,
    @request : HTTP::Request,
    @base_uri : String
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
    query = if params && !params.empty?
              params.compact!
              HTTP::Params.encode params.transform_values &.to_s.as(String)
            end

    port = nil

    # Only bother setting the port if the `port` value can be extracted from the `host` header, and is no a standard port.
    if (host_header = @request.headers["host"]?) && (p = host_header.partition(':').last) && !p.in?("", "80", "443")
      port = p.to_i
    end

    scheme = "https"
    base_uri = nil

    # Apply the `base_uri` parameter parts if present.
    if base_uri = @base_uri.presence
      base_uri = URI.parse base_uri
      scheme = base_uri.scheme
      host = base_uri.host
    else
      host = @request.hostname
    end

    # If there is no host and reference_type is aboslute URL,
    # fallback to absolute path as we wouldn't know what to make the host.
    if !host.presence && reference_type.absolute_url?
      host = nil
      scheme = nil
    end

    path = route.path.gsub(/(?:(:\w+))/, merged_params).gsub(/\/+$/, "")

    uri = URI.new(
      scheme: scheme,
      host: host,
      port: port,
      path: base_uri ? Path.posix(base_uri.request_target).join(path).to_s : path,
      query: query,
      fragment: fragment
    )

    case reference_type
    in .absolute_path?
      String.build do |str|
        str << uri.request_target

        if f = uri.fragment.presence
          str << '#' << f
        end
      end
    in .absolute_url?  then uri.to_s
    in .relative_path? then raise NotImplementedError.new("Relative path reference type is currently not supported.")
    in .network_path?
      uri.scheme = nil
      uri.to_s
    end
  end
end
