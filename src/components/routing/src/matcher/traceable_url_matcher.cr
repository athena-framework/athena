require "./url_matcher"

class Athena::Routing::Matcher::TraceableURLMatcher < Athena::Routing::Matcher::URLMatcher
  enum Match
    NONE
    PARTIAL
    FULL
  end

  record Trace, message : String, level : ART::Matcher::TraceableURLMatcher::Match, name : String? = nil, route : ART::Route? = nil

  @traces = Array(Trace).new

  def initialize(
    @routes : ART::RouteCollection,
    context : ART::RequestContext
  )
    super context
  end

  def traces(@request : ART::Request) : Array(ART::Matcher::TraceableURLMatcher::Trace)
    self.traces @request.not_nil!.path
  ensure
    @request = nil
  end

  def traces(path : String) : Array(ART::Matcher::TraceableURLMatcher::Trace)
    @traces.clear

    begin
      self.match path
    rescue ex : ::Exception
      raise ex unless ex.is_a? ART::Exception
    end

    @traces
  end

  # :inherit:
  def match(path : String) : Hash(String, String?)
    allow = Array(String).new
    allow_schemes = Array(String).new

    if match = self.do_match (URI.decode(path).presence || "/"), allow, allow_schemes, @routes
      return match
    end

    unless allow.empty?
      raise ART::Exception::MethodNotAllowed.new allow
    end

    raise ART::Exception::ResourceNotFound.new "No routes found for '#{path}'."
  end

  # def each_trace(@request : ART::Request, & : ART::Matcher::TraceableURLMatcher::Trace ->) : Nil
  # end

  # def each_trace(path : String, & : ART::Matcher::TraceableURLMatcher::Trace ->) : Nil
  # end
  # ameba:disable Metrics/CyclomaticComplexity
  private def do_match(path : String, allow : Array(String), allow_schemes : Array(String), routes : ART::RouteCollection) : Hash(String, String?)?
    method = @context.method
    method = "GET" if "HEAD" == method

    # ameba:disable Lint/UselessAssign
    supports_trailing_slash = false # TODO: Support this

    trimmed_path = path.rstrip('/').presence || "/"

    routes.each do |name, route|
      compiled_route = route.compile
      static_prefix = compiled_route.static_prefix.rstrip '/'
      required_methods = route.methods

      if !static_prefix.empty? && !trimmed_path.starts_with? static_prefix
        @traces << Trace.new "Path '#{route.path}' does not match", :none, name, route

        next
      end

      regex_source = compiled_route.regex.source

      pos = regex_source.index('$').not_nil!
      has_trailing_slash = '/' == regex_source[pos - 1]

      trailing_slash_padding = has_trailing_slash ? 1 : 0

      start_index = pos - trailing_slash_padding
      end_index = start_index + trailing_slash_padding
      regex_source = regex_source.sub (start_index..end_index), "/?$"
      regex = Regex.new(regex_source)

      unless match = regex.match path
        # Does it match w/o any requirements?
        r = ART::Route.new path: route.path, defaults: route.defaults
        cr = r.compile

        unless cr.regex.matches? path
          @traces << Trace.new "Path '#{route.path}' does not match", :none, name, route

          next
        end

        route.requirements.each do |k, pattern|
          r = ART::Route.new path: route.path, defaults: route.defaults, requirements: {k => pattern}
          cr = r.compile

          if cr.variables.includes?(k) && !path.matches?(cr.regex)
            @traces << Trace.new "Requirement for '#{k}' does not match (#{pattern.source})", :partial, name, route

            break
          end
        end

        next
      end

      has_trailing_var = trimmed_path != path && route.path.matches?(/\{[\w\x80-\xFF]+\}\/?$/)

      if (
           has_trailing_var &&
           (has_trailing_slash || ((n = match[compiled_route.path_variables.size]?).nil?) || ('/' != (n.try &.[-1]? || '/'))) &&
           (sub_match = regex.match(trimmed_path))
         )
        if has_trailing_slash
          match = sub_match
        else
          has_trailing_var = false
        end
      end

      # TODO: Handle host matches
      if (host_pattern = compiled_route.host_regex) && !(host_match = host_pattern.match @context.host)
        @traces << Trace.new "Host '#{@context.host}' does not match the requirement ('#{route.host}')", :partial, name, route

        next
      end

      attributes = self.get_attributes route, name, host_match ? match.to_h.merge(host_match.to_h) : match.to_h
      condition_match = self.handle_route_requirements path, name, route, attributes

      unless condition_match
        @traces << Trace.new "Route condition for '#{name}' does not evaluate to 'true'", :partial, name, route

        next
      end

      if "/" != path && !has_trailing_var && has_trailing_slash == (trimmed_path == path)
        if supports_trailing_slash && (required_methods && (required_methods.empty? || required_methods.includes? "GET"))
          @traces << Trace.new "Route matches!", :full, name, route

          return
        end

        @traces << Trace.new "Path '#{route.path}' does not match", :none, name, route
        next
      end

      if (schemes = route.schemes) && !route.has_scheme(@context.scheme)
        allow_schemes.concat schemes
        @traces << Trace.new "Scheme '#{@context.scheme}' does not match any of the required schemes (#{schemes.join ", "})", :partial, name, route
        next
      end

      if required_methods && !required_methods.includes? method
        allow.concat required_methods
        @traces << Trace.new "Method '#{@context.method}' does not match any of the required methods (#{required_methods.join ", "})", :partial, name, route
        next
      end

      @traces << Trace.new "Route matches!", :full, name, route

      return attributes
    end

    return
  end

  private def get_attributes(route : ART::Route, name : String, attributes : Hash(String | Int32, String?)) : Hash(String, String?)
    defaults = route.defaults

    if canonical_route = defaults["_canonical_route"]?
      name = canonical_route
      defaults.delete "_canonical_route"
    end

    attributes["_route"] = name

    self.merge_defaults attributes, defaults
  end

  private def merge_defaults(params : Hash(String | Int32, String?), defaults : Hash(String, String?)) : Hash(String, String?)
    params.each do |k, v|
      if !k.is_a?(Int) && !v.nil?
        defaults[k] = v
      end
    end

    defaults
  end

  private def handle_route_requirements(path : String, name : String, route : ART::Route, attributes : Hash(String, String?)) : Bool
    if (condition = route.condition) && !condition.call(@context, @request || self.build_request(path))
      return false
    end

    true
  end
end
