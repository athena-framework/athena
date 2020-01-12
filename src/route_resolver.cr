# Registers each route action with the router.  This type is a singleton as opposed to a service to prevent all the routes from having to be redefined on each request.
class Athena::Routing::RouteResolver
  @routes : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

  def initialize
    {% for klass, c_idx in Athena::Routing::Controller.all_subclasses.reject &.abstract? %}
      {% methods = klass.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) || m.annotation(Patch) } %}
      {% class_actions = klass.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) || m.annotation(Patch) } %}

      # Raise compile time error if a route is defined as a class method.
      {% unless class_actions.empty? %}
        {% raise "Routes can only be defined as instance methods.  Did you mean '#{klass.name}##{class_actions.first.name}'?" %}
      {% end %}

      {% parent_prefix = "" %}

      # Add prefixes from parent classes.
      {% for parent in klass.ancestors %}
        {% if (prefix_ann = parent.annotation(Prefix)) %}
          {% if (name = prefix_ann[0] || prefix_ann[:prefix]) %}
            {% parent_prefix = (name.starts_with?('/') ? name : "/" + name) + parent_prefix %}
          {% else %}
           {% raise "Controller '#{parent.name}' has the `Prefix` annotation but is missing the prefix." %}
          {% end %}
        {% end %}
      {% end %}

      # Build out the routes
      {% for m, m_idx in methods %}
        # Raise compile time error if the action doesn't have a return type.
        {% raise "Route action return type must be set for '#{klass.name}##{m.name}'." if m.return_type.is_a? Nop %}

        # Set the route_def and method based on annotation.
        {% if d = m.annotation(Get) %}
          {% method = "GET" %}
          {% route_def = d %}
        {% elsif d = m.annotation(Post) %}
          {% method = "POST" %}
          {% route_def = d %}
        {% elsif d = m.annotation(Put) %}
          {% method = "PUT" %}
          {% route_def = d %}
        {% elsif d = m.annotation(Patch) %}
          {% method = "PATCH" %}
          {% route_def = d %}
        {% elsif d = m.annotation(Delete) %}
          {% method = "DELETE" %}
          {% route_def = d %}
        {% end %}

        # Set and normalize the final prefix if any.
        {% if prefix_ann = klass.annotation(Prefix) %}
          {% if (name = prefix_ann[0] || prefix_ann[:prefix]) %}
            {% prefix = parent_prefix + (name.starts_with?('/') ? name : "/" + name) %}
          {% else %}
           {% raise "Controller '#{klass.name}' has the `Prefix` annotation but is missing the prefix." %}
          {% end %}
        {% else %}
          {% prefix = parent_prefix %}
        {% end %}

        # Grab the path off the annotation.
        {% path = route_def[0] || route_def[:path] %}

        # Raise compile time error if the path is not provided
        {% raise "Route action '#{klass.name}##{m.name}' is annotated as a '#{method.id}' route but is missing the path." unless path %}

        # Normalize the path.
        {% path = path.starts_with?('/') ? path : "/" + path %}

        {% arg_types = m.args.map(&.restriction) %}

        # Build out params and converters array.
        %params{m_idx} = [] of ART::Parameters::Param
        %converters{m_idx} = nil

        {% for arg in m.args %}
          # Raise compile time error if an action argument doesn't have a type restriction.
          {% raise "Route action argument '#{klass.name}##{m.name}:#{arg.name}' must have a type restriction." if arg.restriction.is_a? Nop %}

          {% if arg.restriction.resolve == HTTP::Request %}
            %params{m_idx} << ART::Parameters::RequestParameter(HTTP::Request).new {{arg.name.stringify}}
          {% elsif arg.restriction.resolve == HTTP::Server::Response %}
            %params{m_idx} << ART::Parameters::ResponseParameter(HTTP::Server::Response).new {{arg.name.stringify}}
          # Look for any query parameter annotation defined on `arg`.
          # Raise compile time error if there is an annotation but no action argument.
          {% elsif qp = m.annotations(ART::QueryParam).find { |query_param| (name = query_param[0] || query_param[:name]) ? name == arg.name.stringify : raise "Route action '#{klass.name}##{m.name}'s QueryParam annotation is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field." } %}
            {% if converter = qp[:converter] %}
              %converters{m_idx} = {{converter}}.new
            {% end %}

            %params{m_idx} << ART::Parameters::QueryParameter({{arg.restriction}}).new name: {{name}}, default: {{arg.default_value.is_a?(Nop) ? nil : arg.default_value}}, pattern: {{qp[:constraints]}}, converter: %converters{m_idx}
          {% else %}
            {% converter_ann = m.annotations(ART::ParamConverter).find { |pc| (name = pc[0] || pc[:param]) ? name == arg.name.stringify : raise "Route action '#{klass.name}##{m.name}'s ParamConverter annotation is missing the argument's name.  It was not provided as the first positional argument nor via the 'param' field." } %}

            {% if converter_ann %}
              {% name = converter_ann[0] || converter_ann[:name] %}
              %converters{m_idx} = {{converter_ann[:converter]}}.new
            {% end %}

            %params{m_idx} << ART::Parameters::PathParameter({{arg.restriction}}).new name: {{arg.name.stringify}}, default: {{arg.default_value.is_a?(Nop) ? nil : arg.default_value}}, converter: %converters{m_idx}
          {% end %}
        {% end %}

        # Raise compile time error if the number of action arguments != (queryParams + path arguments + if 1 if there is an HTTP::Request argument).
        {% arg_count = ("/" + method + prefix + path).count(':') + m.annotations(ART::QueryParam).size + (m.args.any? &.restriction.resolve.==(HTTP::Request) ? 1 : 0) + (m.args.any? &.restriction.resolve.==(HTTP::Server::Response) ? 1 : 0) %}
        {% raise "Route action '#{klass.name}##{m.name}' doesn't have the correct number of arguments.  Expected #{arg_count} but got #{m.args.size}." if m.args.size != arg_count %}

        # Add the route to the router
        @routes.add(
          {{"/" + method + prefix + path}},
          # TODO: Just do `Route(ReturnType, *Args)` once https://github.com/crystal-lang/crystal/issues/8520 is fixed.
          Route({{klass.id}}, Proc(Proc({{arg_types.splat}}{% if m.args.size > 0 %},{% end %}{{m.return_type}})), {{m.return_type}}, {{arg_types.splat}}).new(
            ->{ %instance = {{klass.id}}.new; ->%instance.{{m.name.id}}{% if m.args.size > 0 %}({{arg_types.splat}}){% end %} },
            %params{m_idx},
          ){% if constraints = route_def[:constraints] %}, {{constraints}} {% end %}
        )

        # Also add a HEAD endpoint for GET endpoints.
        {% if method == "GET" %}
          @routes.add(
            {{"/HEAD" + prefix + path}},
            # TODO: Just do `Route(ReturnType, *Args)` once https://github.com/crystal-lang/crystal/issues/8520 is fixed.
            Route({{klass.id}}, Proc(Proc({{arg_types.splat}}{% if m.args.size > 0 %},{% end %}{{m.return_type}})), {{m.return_type}}, {{arg_types.splat}}).new(
              ->{ %instance = {{klass.id}}.new; ->%instance.{{m.name.id}}{% if m.args.size > 0 %}({{arg_types.splat}}){% end %} },
              %params{m_idx},
            ){% if constraints = route_def[:constraints] %}, {{constraints}} {% end %}
          )
        {% end %}
      {% end %}
    {% end %}
  end

  # Attempts to resolve the *request* into an `Amber::Router::RoutedResult(Athena::Routing::Action)`.
  #
  # Raises an `ART::Exceptions::NotFound` exception if a corresponding `ART::Route` could not be resolved.
  def resolve(request : HTTP::Request) : Amber::Router::RoutedResult(Athena::Routing::Action)
    route = @routes.find "/#{request.method}#{request.path}"

    raise ART::Exceptions::NotFound.new "No route found for '#{request.method} #{request.path}'" unless route.found?

    route
  end
end
