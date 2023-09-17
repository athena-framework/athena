require "./url_matcher_interface"

# Default implementation of `ART::Matcher::RequestMatcherInterface` and `ART::Matcher::URLMatcherInterface`.
class Athena::Routing::Matcher::URLMatcher
  include Athena::Routing::Matcher::RequestMatcherInterface
  include Athena::Routing::Matcher::URLMatcherInterface

  property context : ART::RequestContext

  @request : ART::Request? = nil

  def initialize(@context : ART::RequestContext); end

  # :inherit:
  def match(@request : ART::Request) : Hash(String, String?)
    self.match @request.not_nil!.path
  ensure
    @request = nil
  end

  # :inherit:
  def match?(@request : ART::Request) : Hash(String, String?)?
    self.match? @request.not_nil!.path
  ensure
    @request = nil
  end

  # :inherit:
  def match(path : String) : Hash(String, String?)
    allow = Array(String).new
    allow_schemes = Array(String).new

    if match = self.do_match path, allow, allow_schemes
      return match
    end

    unless allow.empty?
      raise ART::Exception::MethodNotAllowed.new allow
    end

    unless self.is_a? ART::Matcher::RedirectableURLMatcherInterface
      raise ART::Exception::ResourceNotFound.new "No routes found for '#{path}'."
    end

    if !@context.method.in? "GET", "HEAD"
      # no-op
    elsif !allow_schemes.empty?
      redirect_schema
    elsif "/" != (trimmed_path = (path.rstrip('/').presence || "/"))
      path = trimmed_path == path ? "#{path}/" : trimmed_path

      if match = self.do_match path, allow, allow_schemes
        return match.merge! self.redirect(path, match["_route"].not_nil!("BUG: match does not have a '_route'."))
      end

      unless allow_schemes.empty?
        redirect_schema
      end
    end

    raise ART::Exception::ResourceNotFound.new "No routes found for '#{path}'."
  end

  # :inherit:
  def match?(path : String) : Hash(String, String?)?
    self.do_match path, Array(String).new, Array(String).new
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def do_match(path : String, allow : Array(String) = [] of String, allow_schemes : Array(String) = [] of String) : Hash(String, String?)?
    allow.clear
    allow_schemes.clear

    path = URI.decode(path).presence || "/"
    path = path.presence || "/"
    trimmed_path = path.rstrip('/').presence || "/"
    request_method = canonical_method = @context.method

    host = @context.host.downcase if ART::RouteProvider.match_host?

    canonical_method = "GET" if "HEAD" == request_method

    supports_redirect = "GET" == canonical_method && self.is_a? ART::Matcher::RedirectableURLMatcherInterface

    ART::RouteProvider.static_routes[trimmed_path]?.try &.each do |data, required_host, required_methods, required_schemes, has_trailing_slash, _, condition|
      if condition && !(ART::RouteProvider.conditions[condition].call(@context, @request || self.build_request(path)))
        next
      end

      # Dup the data hash so we don't mutate the original.
      data = data.dup

      if h = required_host
        case h
        in String then next if h != host
        in Regex
          if match = host.try &.match h
            host_matches = match.named_captures
            host_matches["_route"] = data["_route"]

            host_matches.each do |key, value|
              data[key] = value unless value.nil?
            end
          else
            next
          end
        end
      end

      if "/" != path && has_trailing_slash == (trimmed_path == path)
        if supports_redirect && (!required_methods || (required_methods.empty? || required_methods.includes? "GET"))
          allow.clear
          allow_schemes.clear

          return
        end

        next
      end

      # TODO: Check schemas
      has_required_scheme = required_schemes.nil? || required_schemes.includes? @context.scheme
      if has_required_scheme && required_methods && !required_methods.includes?(canonical_method) && !required_methods.includes?(request_method)
        allow.concat required_methods
        next
      end

      if !has_required_scheme
        required_schemes.try do |schemes|
          allow_schemes.concat schemes
        end
        next
      end

      return data
    end

    matched_path = ART::RouteProvider.match_host? ? "#{host}.#{path}" : path

    ART::RouteProvider.route_regexes.each do |offset, regex|
      while match = regex.match matched_path
        ART::RouteProvider.dynamic_routes[matched_mark = match.mark.not_nil!]?.try &.each do |data, vars, required_methods, required_schemes, has_trailing_slash, has_trailing_var, condition|
          # Dup the data hash so we don't mutate the original.
          data = data.dup

          if condition && !(ART::RouteProvider.conditions[condition].call(@context, @request || self.build_request(path)))
            next
          end

          has_trailing_var = trimmed_path != path && has_trailing_var

          if has_trailing_var &&
             (has_trailing_slash || (!vars || (n = match[vars.size]?).nil?) || ('/' != (n.try &.[-1]? || '/'))) &&
             (sub_match = regex.match(ART::RouteProvider.match_host? ? "#{host}.#{trimmed_path}" : trimmed_path)) && (matched_mark == sub_match.mark.not_nil!)
            if has_trailing_slash
              match = sub_match
            else
              has_trailing_var = false
            end
          end

          if "/" != path && !has_trailing_var && has_trailing_slash == (trimmed_path == path)
            if supports_redirect && (!required_methods || (required_methods.empty? || required_methods.includes? "GET"))
              allow.clear
              allow_schemes.clear

              return
            end

            next
          end

          vars.try &.each_with_index do |var, idx|
            if m = match[idx + 1]?
              data[var] = m
            end
          end

          if required_schemes && required_schemes.includes? @context.scheme
            allow_schemes.concat required_schemes
            next
          end

          if required_methods && !required_methods.includes?(canonical_method) && !required_methods.includes?(request_method)
            allow.concat required_methods
            next
          end

          return data
        end

        regex = ART.create_regex regex.source.sub "(*:#{matched_mark})", "(*F)"
        offset += matched_mark.size
      end
    end

    if "/" == path && allow.empty? && allow_schemes.empty?
      raise ART::Exception::NoConfiguration.new
    end

    nil
  end

  private def build_request(path : String) : ART::Request
    request = HTTP::Request.new(
      @context.method,
      "#{@context.base_url}#{path}",
      headers: HTTP::Headers{
        "host" => %(#{@context.host}:#{"http" == @context.scheme ? @context.http_port : @context.https_port}),
      }
    )

    {% if @top_level.has_constant?("Athena") && Athena.has_constant?("Framework") && Athena::Framework.has_constant?("Request") %}
      request = Athena::Framework::Request.new request
    {% end %}

    request
  end

  private macro redirect_schema
    scheme = @context.scheme
    @context.scheme = allow_schemes.last? || ""

    begin
      if match = self.do_match path
        return match.merge! self.redirect(path, match["_route"].not_nil!("BUG: match does not have a '_route'."), @context.scheme)
      end
    ensure
      @context.scheme = scheme
    end
  end
end
