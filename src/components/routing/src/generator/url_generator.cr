# Default implementation of `ART::Generator::Interface`.
class Athena::Routing::Generator::URLGenerator
  include Athena::Routing::Generator::Interface
  include Athena::Routing::Generator::ConfigurableRequirementsInterface

  # Maps some chars that should be displayed in their raw form and _NOT_ percent encoded, for reasons below.
  private DECODED_CHARS = {
    # the slash can be used to designate a hierarchical structure and we want allow using it with this meaning
    # some webservers don't allow the slash in encoded form in the path for security reasons anyway
    # see http://stackoverflow.com/questions/4069002/http-400-if-2f-part-of-get-url-in-jboss
    "%2F"   => "/",
    "%252F" => "%2F",

    # the following chars are general delimiters in the URI specification but have only special meaning in the authority component
    # so they can safely be used in the path in unencoded form
    "%40" => "@",
    "%3A" => ":",

    # these chars are only sub-delimiters that have no predefined meaning and can therefore be used literally
    # so URI producing applications can use these chars to delimit subcomponents in a path segment without being encoded for better readability
    "%3B" => ";",
    "%2C" => ",",
    "%3D" => "=",
    "%2B" => "+",
    "%21" => "!",
    "%2A" => "*",
    "%7C" => "|",
  }

  private DECODED_QUERY_FRAGMENT_CHARS = {
    # RFC 3986 explicitly allows those in the query/fragment to reference other URIs unencoded
    "%2F"   => "/",
    "%252F" => "%2F",
    "%3F"   => "?",

    # reserved chars that have no special meaning for HTTP URIs in a query or fragment
    # this excludes esp. "&", "=" and also "+" because PHP would treat it as a space (form-encoded)
    "%40" => "@",
    "%3A" => ":",
    "%21" => "!",
    "%3B" => ";",
    "%2C" => ",",
    "%2A" => "*",
  }

  # :inherit:
  property context : ART::RequestContext

  # :inherit:
  getter? strict_requirements : Bool? = true

  def initialize(
    @context : ART::RequestContext,
    @default_locale : String? = nil,
    @route_provider : ART::RouteProvider.class = ART::RouteProvider,
  )
  end

  def strict_requirements=(enabled : Bool?)
    @strict_requirements = enabled
  end

  # :inherit:
  def generate(route : String, params : Hash(String, String?) = Hash(String, String?).new, reference_type : ART::Generator::ReferenceType = :absolute_path) : String
    if locale = params["_locale"]? || @context.parameters["_locale"]? || @default_locale
      if (locale_route = @route_provider.route_generation_data["#{route}.#{locale}"]?) && (route == locale_route[1]["_canonical_route"]?)
        route = "#{route}.#{locale}"
      end
    end

    unless generation_data = @route_provider.route_generation_data[route]?
      raise ART::Exception::RouteNotFound.new "No route with the name '#{route}' exists."
    end

    variables, defaults, requirements, tokens, host_tokens, schemes = generation_data

    if defaults.has_key?("_canonical_route") && defaults.has_key?("_locale")
      if !variables.includes? "_locale"
        params.delete "_locale"
      elsif !params.has_key?("_locale")
        params = params.merge({"_locale" => defaults["_locale"]})
      end
    end

    self.do_generate variables, defaults, requirements, tokens, params, route, reference_type, host_tokens, schemes
  end

  # :ditto:
  def generate(route : String, reference_type : ART::Generator::ReferenceType = :absolute_path, **params) : String
    self.generate route, params.to_h.transform_keys(&.to_s), reference_type
  end

  # :ditto:
  def generate(route : String, params : Hash(String, _) = Hash(String, String?).new, reference_type : ART::Generator::ReferenceType = :absolute_path) : String
    self.generate route, params.transform_values { |v| v.nil? ? v : v.to_s }, reference_type
  end

  # OPTIMIZE: We could probably make use of `URI` for a lot of this stuff.
  #
  # ameba:disable Metrics/CyclomaticComplexity
  private def do_generate(
    variables : Set(String),
    defaults : Hash(String, String?),
    requirements : Hash(String, Regex),
    tokens : Array(ART::CompiledRoute::Token),
    params : Hash(String, String?),
    name : String,
    reference_type : ART::Generator::ReferenceType,
    host_tokens : Array(ART::CompiledRoute::Token),
    required_schemes : Set(String)?,
  ) : String
    merged_params = Hash(String, String?).new
    merged_params.merge! defaults
    merged_params.merge! @context.parameters
    merged_params.merge! params

    unless (missing_params = variables - merged_params.keys).empty?
      raise ART::Exception::MissingRequiredParameters.new %(Cannot generate URL for route '#{name}'. Missing required parameters: #{missing_params.join(", ") { |p| "'#{p}'" }}.)
    end

    url = ""
    optional = true
    message = "Parameter '%s' for route '%s' must match '%s' (got '%s') to generate the corresponding URL."
    tokens.each do |token|
      case token.type
      in .variable?
        var_name = token.var_name
        important = token.important?

        if !optional || important || !defaults.has_key?(var_name) || (!merged_params[var_name]?.nil? && merged_params[var_name].to_s != defaults[var_name].to_s)
          if !@strict_requirements.nil? && (r = token.regex) && !(merged_params[token.var_name]? || "").to_s.matches?(/^#{r.source.gsub /\(\?(?:=|<=|!|<!)((?:[^()\\]+|\\.|\((?1)\))*)\)/, ""}$/i)
            if @strict_requirements
              raise ART::Exception::InvalidParameter.new message % {var_name, name, r, merged_params[var_name]}
            end

            # TODO: Add logger integration

            return ""
          end

          url = "#{token.prefix}#{merged_params[var_name]}#{url}"
          optional = false
        end
      in .text?
        url = "#{token.prefix}#{url}"
        optional = false
      end
    end

    url = "/" if url.empty?

    url = URI.encode_path(url).gsub Regex.union(DECODED_CHARS.keys), DECODED_CHARS

    url = url.gsub Regex.union((hash = {"/../" => "/%2E%2E/", "/./" => "/%2E/"}).keys), hash

    if url.ends_with? "/.."
      url = url.sub (-2..-1), "%2E%2E"
    elsif url.ends_with? "/."
      url = url.sub -1, "%2E"
    end

    scheme_authority = ""
    host = @context.host
    scheme = @context.scheme

    if required_schemes
      unless required_schemes.includes? scheme
        reference_type = ART::Generator::ReferenceType::ABSOLUTE_URL
        scheme = required_schemes.to_a.first
      end
    end

    unless host_tokens.empty?
      route_host = ""

      host_tokens.each do |token|
        case token.type
        in .variable?
          if !@strict_requirements.nil? && (r = token.regex) && !(merged_params[token.var_name]? || "").to_s.matches?(/^#{r.source.gsub /\(\?(?:=|<=|!|<!)((?:[^()\\]+|\\.|\((?1)\))*)\)/, ""}$/i)
            if @strict_requirements
              raise ART::Exception::InvalidParameter.new message % {token.var_name, name, r, merged_params[token.var_name]}
            end

            # TODO: Add logger integration

            return ""
          end

          route_host = "#{token.prefix}#{merged_params[token.var_name]}#{route_host}"
        in .text?
          route_host = "#{token.prefix}#{route_host}"
        end
      end

      if route_host != host
        host = route_host
        reference_type = ART::Generator::ReferenceType::NETWORK_PATH unless reference_type.absolute_url?
      end
    end

    if reference_type.absolute_url? || reference_type.network_path?
      if !host.empty? || (!scheme.in? "", "https", "http")
        port = ""

        if "http" == scheme && 80 != @context.http_port
          port = ":#{@context.http_port}"
        elsif "https" == scheme && 443 != @context.https_port
          port = ":#{@context.https_port}"
        end

        scheme_authority = reference_type.network_path? || scheme.empty? ? "//" : "#{scheme}://"
        scheme_authority = "#{scheme_authority}#{host}#{port}"
      end
    end

    if reference_type.relative_path?
      url = if @context.path == url
              ""
            else
              URI.new(path: @context.path).relativize(URI.new path: url).to_s
            end
    else
      url = "#{scheme_authority}#{@context.base_url}#{url}"
    end

    extra_params = params.reject { |key, value| variables.includes?(key) || defaults[key]? == value }

    fragment = defaults["_fragment"]? || ""

    if frag = extra_params.delete("_fragment")
      fragment = frag.to_s.presence || ""
    end

    unless extra_params.empty?
      query = URI::Params.encode(extra_params.transform_values(&.to_s.as(String)).select! { |_, value| value.presence }).gsub Regex.union(DECODED_QUERY_FRAGMENT_CHARS.keys), DECODED_QUERY_FRAGMENT_CHARS
    end

    if query.presence
      url = "#{url}?#{query}"
    end

    unless fragment.empty?
      url = "#{url}##{URI.encode_path_segment(fragment).gsub Regex.union(DECODED_QUERY_FRAGMENT_CHARS.keys), DECODED_QUERY_FRAGMENT_CHARS}"
    end

    url
  end
end
