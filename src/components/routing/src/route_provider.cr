require "./static_prefix_collection"

# :nodoc:
#
# Exposes getters to static/dynamic routes as well as the full route regex.
# Values are cached on the class level for performance resaons.
class Athena::Routing::RouteProvider
  private alias Condition = Athena::Routing::Route::Condition

  # We store this as a tuple in order to get splatting/unpacking features.
  # defaults, variables, methods, schemas, trailing slash?, trailing var?, conditions
  alias DynamicRouteData = Tuple(Hash(String, String?), Set(String)?, Set(String)?, Set(String)?, Bool, Bool, Int32?)

  # We store this as a tuple in order to get splatting/unpacking features.
  # defaults, host, methods, schemas, trailing slash?, trailing var?, conditions
  alias StaticRouteData = Tuple(Hash(String, String?), String | Regex | Nil, Set(String)?, Set(String)?, Bool, Bool, Int32?)

  # We store this as a tuple in order to get splatting/unpacking features.
  # variables, defaults, requirements, tokens, host tokens, schemes
  alias RouteGenerationData = Tuple(Set(String), Hash(String, String?), Hash(String, Regex), Array(ART::CompiledRoute::Token), Array(ART::CompiledRoute::Token), Set(String)?)

  private record PreCompiledStaticRoute, route : ART::Route, has_trailing_slash : Bool
  private record PreCompiledDynamicRegex, host_regex : Regex?, regex : Regex, static_prefix : String
  private record PreCompiledDynamicRoute, pattern : String, routes : ART::RouteCollection

  private class State
    property vars : Set(String) = Set(String).new
    property host_vars : Set(String) = Set(String).new
    property mark : Int32 = 0
    property mark_tail : Int32 = 0
    getter routes : Hash(String, Array(DynamicRouteData))
    property regex : String = ""

    def initialize(@routes : Hash(String, Array(DynamicRouteData))); end

    def vars(subject : String, regex : Regex) : String
      subject.gsub(regex) do |_, match|
        next "?:" if "_route" == match[1]

        @vars << match[1].to_s

        ""
      end
    end
  end

  class_getter match_host : Bool = false
  class_getter static_routes : Hash(String, Array(StaticRouteData)) = Hash(String, Array(StaticRouteData)).new
  class_getter route_regexes : Hash(Int32, Regex) = Hash(Int32, Regex).new
  class_getter dynamic_routes : Hash(String, Array(DynamicRouteData)) = Hash(String, Array(DynamicRouteData)).new
  class_getter conditions : Hash(Int32, Condition) = Hash(Int32, Condition).new
  class_getter route_generation_data : Hash(String, RouteGenerationData) = Hash(String, RouteGenerationData).new

  protected class_getter? compiled : Bool = false

  def self.compile(routes : ART::RouteCollection) : Nil
    return if @@compiled

    @@routes = routes

    self.compile
  end

  def self.inspect(io : IO) : Nil
    io << "Match Host:  "
    self.match_host.inspect io
    io << "\n\nStatic Routes:  "
    self.static_routes.inspect io
    io << "\n\nRegexes:  "
    self.route_regexes.inspect io
    io << "\n\nDynamic Routes:  "
    self.dynamic_routes.inspect io
    io << "\n\nConditions:  "
    self.conditions.inspect io
    io << "\n\nRoute Generation Data:  "
    self.route_generation_data.inspect io
    io << "\n\n"
  end

  protected def self.reset : Nil
    @@match_host = false
    @@static_routes.clear
    @@dynamic_routes.clear
    @@route_regexes.clear
    @@conditions.clear
    @@route_generation_data.clear
    @@compiled = false
    @@routes = nil
  end

  private def self.compile : Nil
    match_host = false
    routes = ART::RouteProvider::StaticPrefixCollection.new

    self.routes.each do |name, route|
      if host = route.host
        match_host = true

        host = %(/#{host.reverse.tr "}.{", "(/)"})
      end

      routes.add_route (host || "/(.*)"), ART::RouteProvider::StaticPrefixCollection::StaticTreeNamedRoute.new name, route
    end

    if match_host
      @@match_host = true
      routes = routes.populate_collection ART::RouteCollection.new
    else
      @@match_host = false
      routes = self.routes
    end

    static_routes, dynamic_routes = self.group_static_routes routes

    conditions = Array(Condition).new

    self.compile_static_routes static_routes, conditions

    chunk_limit = dynamic_routes.size

    loop do
      self.compile_dynamic_routes dynamic_routes, match_host, chunk_limit, conditions
      break
    rescue e : ArgumentError
      if 1 < chunk_limit && e.message.try(&.starts_with?("regular expression is too large"))
        chunk_limit = 1 + (chunk_limit >> 1)
        next
      end

      raise e
    end

    self.routes.each do |name, route|
      compiled_route = route.compile

      @@route_generation_data[name] = {
        compiled_route.variables,
        route.defaults,
        route.requirements,
        compiled_route.tokens,
        compiled_route.host_tokens,
        route.schemes,
      }
    end

    @@compiled = true
    @@routes = nil
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def self.compile_dynamic_routes(collection : ART::RouteCollection, match_host : Bool, chunk_limit : Int, conditions : Array(Condition)) : Nil
    dr = Hash(String, Array(DynamicRouteData)).new

    if collection.empty?
      return @@dynamic_routes = dr
    end

    state = State.new dr

    chunk_size = 0
    routes = nil
    collections = Array(ART::RouteCollection).new

    collection.each do |name, route|
      if chunk_limit < (chunk_size += 1) || routes.nil?
        chunk_size = 1
        routes = ART::RouteCollection.new
        collections << routes
      end

      routes.not_nil!.add name, route
    end

    collections.each do |sub_collection|
      previous_regex = false
      per_host_routes = Array(Tuple(Regex?, ART::RouteCollection)).new
      host_routes = nil

      sub_collection.each do |name, route|
        regex = route.compile.host_regex
        if previous_regex != regex
          host_routes = ART::RouteCollection.new
          per_host_routes << {regex, host_routes}
          previous_regex = regex
        end

        host_routes.not_nil!.add name, route
      end

      previous_regex = false
      final_regex = "^(?"
      starting_mark = state.mark
      state.mark += final_regex.size + 1 # Add 1 to account for the eventual `/`.
      state.regex = final_regex

      per_host_routes.each do |host_regex, sub_routes|
        if match_host
          if host_regex
            host_regex.source.match(/^\^(.*)\$$/).try do |match|
              state.vars = Set(String).new
              host_regex = state.vars match[1], /\?P<([^>]++)>/
              host_regex = Regex.new "(?i:#{host_regex})\\."
              state.host_vars = state.vars
            end
          else
            host_regex = /(?:(?:[^.\/]*+\.)++)/
            state.host_vars = Set(String).new
          end

          pattern = %<#{previous_regex ? ")" : ""}|#{host_regex.source}(?>
          state.mark += pattern.size
          state.regex += pattern
          previous_regex = true
        end

        tree = ART::RouteProvider::StaticPrefixCollection.new

        sub_routes.each do |name, route|
          matched_regex = route.compile.regex.source.match(/\^(.*)\$$/).not_nil!

          state.vars = Set(String).new
          pattern = state.vars matched_regex[1], /\?P<([^>]++)>/

          if has_trailing_slash = "/" != pattern && pattern.ends_with? '/'
            pattern = pattern.rchop '/'
          end

          has_trailing_var = route.path.matches? /\{\w+\}\/?$/

          tree.add_route pattern, ART::RouteProvider::StaticPrefixCollection::StaticPrefixTreeRoute.new name, pattern, state.vars, route, has_trailing_slash, has_trailing_var
        end

        self.compile_static_prefix_collection tree, state, 0, conditions
      end

      if match_host
        state.regex += ")"
      end

      state.regex += ")/?$"
      state.mark_tail = 0

      @@route_regexes[starting_mark] = ART.create_regex state.regex
    end

    @@dynamic_routes = state.routes
  end

  private def self.compile_static_prefix_collection(tree : ART::RouteProvider::StaticPrefixCollection, state : State, prefix_length : Int32, conditions) : Nil
    previous_regex = nil

    tree.items.each do |item|
      case item
      in ART::RouteProvider::StaticPrefixCollection
        previous_regex = nil
        prefix = item.prefix[prefix_length..]
        pattern = "|#{prefix}(?"
        state.mark += pattern.size
        state.regex += pattern

        self.compile_static_prefix_collection item, state, prefix_length + prefix.size, conditions

        state.regex += ")"
        state.mark_tail += 1

        next
      in ART::RouteProvider::StaticPrefixCollection::StaticPrefixTreeRoute
        compiled_route = item.route.compile
        vars = state.host_vars + item.variables

        if compiled_route.regex == previous_regex
          state.routes[state.mark.to_s] << self.compile_dynamic_route item.route, item.name, vars, item.has_trailing_slash, item.has_trailing_var, conditions
          next
        end

        state.mark += 3 + state.mark_tail + item.pattern.size - prefix_length
        state.mark_tail = 2 + state.mark.digits.size

        state.regex += "|#{item.pattern[prefix_length..]}(*:#{state.mark})"

        previous_regex = compiled_route.regex
        state.routes[state.mark.to_s] = [self.compile_dynamic_route item.route, item.name, vars, item.has_trailing_slash, item.has_trailing_var, conditions] of DynamicRouteData
      in ART::RouteProvider::StaticPrefixCollection::StaticTreeNamedRoute
        raise "BUG: StaticTreeNamedRoute"
      in ART::RouteProvider::StaticPrefixCollection::StaticTreeName
        raise "BUG: StaticTreeName"
      end
    end
  end

  private alias StaticRoutes = Hash(String, Hash(String, PreCompiledStaticRoute))

  private def self.compile_static_routes(static_routes : StaticRoutes, conditions : Array(Condition)) : Nil
    return if static_routes.empty?

    sr = Hash(String, Array(StaticRouteData)).new

    static_routes.each do |url, routes|
      sr[url] = Array(StaticRouteData).new routes.size

      routes.each do |name, pre_compiled_route|
        route = pre_compiled_route.route

        host = if route.compile.host_variables.empty?
                 route.host
               elsif regex = route.compile.host_regex
                 regex
               end

        sr[url] << self.compile_static_route(
          route,
          name,
          host,
          pre_compiled_route.has_trailing_slash,
          false,
          conditions
        )
      end
    end

    @@static_routes = sr
  end

  private def self.compile_dynamic_route(route : ART::Route, name : String, vars : Set(String)?, has_trailing_slash : Bool, has_trailing_var : Bool, conditions : Array(Condition)) : DynamicRouteData
    defaults = route.defaults.dup

    if canonical_route = defaults["_canonical_route"]?
      name = canonical_route
      defaults.delete "_canonical_route"
    end

    if condition = route.condition
      @@conditions[condition_key = 1 * @@conditions.size] = condition
    end

    {
      Hash(String, String?){"_route" => name}.merge!(defaults),
      vars,
      route.methods,
      route.schemes,
      has_trailing_slash,
      has_trailing_var,
      condition_key,
    }
  end

  private def self.compile_static_route(route : ART::Route, name : String, host : String | Regex | Nil, has_trailing_slash : Bool, has_trailing_var : Bool, conditions : Array(Condition)) : StaticRouteData
    defaults = route.defaults.dup

    if canonical_route = defaults["_canonical_route"]?
      name = canonical_route
      defaults.delete "_canonical_route"
    end

    if condition = route.condition
      @@conditions[condition_key = 1 * @@conditions.size] = condition
    end

    {
      Hash(String, String?){"_route" => name}.merge!(defaults),
      host,
      route.methods,
      route.schemes,
      has_trailing_slash,
      has_trailing_var,
      condition_key,
    }
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def self.group_static_routes(routes : ART::RouteCollection) : Tuple(StaticRoutes, ART::RouteCollection)
    static_routes = Hash(String, Hash(String, PreCompiledStaticRoute)).new { |hash, key| hash[key] = Hash(String, PreCompiledStaticRoute).new }
    dynamic_regex = Array(PreCompiledDynamicRegex).new
    dynamic_routes = ART::RouteCollection.new

    routes.each do |name, route|
      compiled_route = route.compile
      static_prefix = compiled_route.static_prefix.rstrip '/'
      host_regex = compiled_route.host_regex
      regex = compiled_route.regex

      has_trailing_slash = "/" != route.path

      if has_trailing_slash
        pos = regex.source.index('$').not_nil!
        has_trailing_slash = '/' == regex.source[pos - 1]
        regex = Regex.new regex.source.sub (1 + pos - (has_trailing_slash ? 1 : 0))..-((has_trailing_slash ? 1 : 0)), "/?$"
      end

      if compiled_route.path_variables.empty?
        host = compiled_route.host_variables.empty? ? "" : route.host
        url = route.path

        if has_trailing_slash
          url = url.rstrip '/'
        end

        should_next = dynamic_regex.each do |dr|
          host_regex_matches = host ? dr.host_regex.try &.matches?(host) : false

          if (
               (dr.static_prefix.empty? || url.starts_with?(dr.static_prefix)) &&
               (dr.regex.matches?(url) || dr.regex.matches?("#{url}/")) &&
               (host.presence.nil? || host_regex.nil? || host_regex_matches)
             )
            dynamic_regex << PreCompiledDynamicRegex.new host_regex, regex, static_prefix
            dynamic_routes.add name, route
            break true
          end
        end

        next if should_next

        static_routes[url][name] = PreCompiledStaticRoute.new route, has_trailing_slash
      else
        dynamic_regex << PreCompiledDynamicRegex.new host_regex, regex, static_prefix
        dynamic_routes.add name, route
      end
    end

    {static_routes, dynamic_routes}
  end

  private def self.routes : ART::RouteCollection
    @@routes || raise "Routes have not been compiled. Did you forget to call `ART.compile`?"
  end
end
