# Registers an `ART::Route` for each action with the router.  This type is a singleton as opposed to a service to prevent all the routes from having to be redefined on each request.
class Athena::Routing::RouteResolver
  @router : Amber::Router::RouteSet(Action) = Amber::Router::RouteSet(Action).new

  def initialize
    {% begin %}
      # Define a hash to store registered routes.  Will be used to raise on duplicate routes.
      {% registered_routes = {} of String => String %}

      {% for klass, c_idx in Athena::Routing::Controller.all_subclasses.reject &.abstract? %}
        {% methods = klass.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) || m.annotation(Patch) } %}
        {% class_actions = klass.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) || m.annotation(Patch) } %}

        # Raise compile time error if a route is defined as a class method.
        {% unless class_actions.empty? %}
          {% class_actions.first.raise "Routes can only be defined as instance methods.  Did you mean '#{klass.name}##{class_actions.first.name}'?" %}
        {% end %}

        {% parent_prefix = "" %}

        # Add prefixes from parent classes.
        {% for parent in klass.ancestors %}
          {% if (prefix_ann = parent.annotation(Prefix)) %}
            {% if (name = prefix_ann[0] || prefix_ann[:prefix]) %}
              {% parent_prefix = (name.starts_with?('/') ? name : "/" + name) + parent_prefix %}
            {% else %}
             {% klass.raise "Controller '#{parent.name}' has the `Prefix` annotation but is missing the prefix." %}
            {% end %}
          {% end %}
        {% end %}

        # Build out the routes
        {% for m in methods %}
          # Raise compile time error if the action doesn't have a return type.
          {% m.raise "Route action return type must be set for '#{klass.name}##{m.name}'." if m.return_type.is_a? Nop %}

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
             {% klass.raise "Controller '#{klass.name}' has the `Prefix` annotation but is missing the prefix." %}
            {% end %}
          {% else %}
            {% prefix = parent_prefix %}
          {% end %}

          # Grab the path off the annotation.
          {% path = route_def[0] || route_def[:path] %}

          # Raise compile time error if the path is not provided
          {% m.raise "Route action '#{klass.name}##{m.name}' is annotated as a '#{method.id}' route but is missing the path." unless path %}

          # Normalize the path.
          {% path = path.starts_with?('/') ? path : "/" + path %}

          # Build the full path
          {% full_path = prefix + path %}

          # Normalize the full path to see if it was already registered.
          {% normalized_path = (method + full_path).gsub(/\/:.+?(?:\/|$)/, "/path_argument/") %}

          # Check if this route was already registered
          {% if conflicting_route = registered_routes[normalized_path] %}
            # If the path was previously registered, and both don't have constraints or they're equal, raise a compile time error
            {% if (!conflicting_route[:constraints] && !route_def[:constraints]) || ((previous_constraints = conflicting_route[:constraints]) && (current_constraint = route_def[:constraints]) && previous_constraints == current_constraint) %}
              {% m.raise "Route action #{klass.name}##{m.name}'s path #{full_path} conflicts with #{conflicting_route[:action]}'s path #{conflicting_route[:path]}." %}
            {% end %}
          {% else %}
            {% registered_routes[normalized_path] = {action: "#{klass.name}##{m.name}".id, path: full_path, constraints: route_def[:constraints]} %}
          {% end %}

          # Get an array of the action's argument's types and names.
          {% arg_types = m.args.map &.restriction %}
          {% arg_names = m.args.map &.name.stringify %}

          # Build out arguments array.
          {% arguments = [] of Nil %}

          {% for arg in m.args %}
            # Raise compile time error if an action argument doesn't have a type restriction.
            {% arg.raise "Route action argument '#{klass.name}##{m.name}:#{arg.name}' must have a type restriction." if arg.restriction.is_a? Nop %}
            {% arguments << %(ART::Arguments::ArgumentMetadata(#{arg.restriction}).new(#{arg.name.stringify}, #{!arg.default_value.is_a?(Nop)}, #{arg.restriction.resolve.nilable?}, #{arg.default_value.is_a?(Nop) ? nil : arg.default_value})).id %}
          {% end %}

          # Build out param converters array.
          {% param_converters = [] of Nil %}

          {% for converter in m.annotations(ART::ParamConverter) %}
            {% converter.raise "Route action '#{klass.name}##{m.name}' has an ART::ParamConverter annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field." unless arg_name = (converter[0] || converter[:name]) %}
            {% converter.raise "Route action '#{klass.name}##{m.name}' has an ART::ParamConverter annotation but does not have a corresponding action argument for '#{arg_name.id}'." unless arg_names.includes? arg_name %}
            {% converter.raise "Route action '#{klass.name}##{m.name}' has an ART::ParamConverter annotation but is missing the converter class.  It was not provided via the 'converter' field." unless converter_class = converter[:converter] %}
            {% param_converters << %(#{converter_class.resolve}::Configuration.new(name: #{arg_name.id.stringify}, #{converter.named_args.double_splat})).id %}
          {% end %}

          # Make sure query params have a corresponding action argument.
          {% for qp in m.annotations(ART::QueryParam) %}
            {% qp.raise "Route action '#{klass.name}##{m.name}' has an ART::QueryParam annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field." unless arg_name = (qp[0] || qp[:name]) %}
            {% qp.raise "Route action '#{klass.name}##{m.name}' has an ART::QueryParam annotation but does not have a corresponding action argument for '#{arg_name.id}'." unless arg_names.includes? arg_name %}
          {% end %}

          # Add the route to the router
          @router.add(
            {{full_path}},
            Route.new(
              ->{
                  # If the controller is not registered as a service, simply new one up
                  # TODO: Replace this with a compiler pass after https://github.com/crystal-lang/crystal/pull/9091 is released
                  {% if ann = klass.annotation(ADI::Register) %}
                    {% klass.raise "Controller service '#{klass.id}' must be declared as public." unless ann[:public] %}
                    %instance = ADI.container.get({{klass.id}})
                  {% else %}
                    %instance = {{klass.id}}.new
                  {% end %}

                  ->%instance.{{m.name.id}}{% if !m.args.empty? %}({{arg_types.splat}}){% end %}
                },
              {{m.name.stringify}},
              {{method}},
              {{arguments.empty? ? "Array(ART::Arguments::ArgumentMetadata(Nil)).new".id : arguments}},
              ({{param_converters}} of ART::ParamConverterInterface::ConfigurationInterface),
              {{klass.id}},
              {{m.return_type}},
              {{arg_types.empty? ? "typeof(Tuple.new)".id : "Tuple(#{arg_types.splat})".id}}
            ){% if constraints = route_def[:constraints] %}, {{constraints}} {% end %}
          )

          # Also add a HEAD route for GET endpoints.
          {% if method == "GET" %}
            @router.add(
              {{full_path}},
              Route.new(
                ->{
                  # If the controller is not registered as a service, simply new one up
                  # TODO: Replace this with a compiler pass after https://github.com/crystal-lang/crystal/pull/9091 is released
                  {% if ann = klass.annotation(ADI::Register) %}
                    {% klass.raise "Controller service '#{klass.id}' must be declared as public." unless ann[:public] %}
                    %instance = ADI.container.get({{klass.id}})
                  {% else %}
                    %instance = {{klass.id}}.new
                  {% end %}

                  ->%instance.{{m.name.id}}{% if !m.args.empty? %}({{arg_types.splat}}){% end %}
                },
                {{m.name.stringify}},
                "HEAD",
                {{arguments.empty? ? "Array(ART::Arguments::ArgumentMetadata(Nil)).new".id : arguments}},
                ({{param_converters}} of ART::ParamConverterInterface::ConfigurationInterface),
                {{klass.id}},
                {{m.return_type}},
                {{arg_types.empty? ? "typeof(Tuple.new)".id : "Tuple(#{arg_types.splat})".id}}
              ){% if constraints = route_def[:constraints] %}, {{constraints}} {% end %}
            )
          {% end %}
        {% end %}
      {% end %}
    {% end %}
  end

  # Attempts to resolve the *request* into an `Amber::Router::RoutedResult(Athena::Routing::Action)`.
  #
  # Raises an `ART::Exceptions::NotFound` exception if a corresponding `ART::Route` could not be resolved.
  # Raises an `ART::Exceptions::MethodNotAllowed` exception if a route was matched but does not support the *request*'s method.
  def resolve(request : HTTP::Request) : Amber::Router::RoutedResult(Athena::Routing::Action)
    # Get the routes that match the given path
    matching_routes = @router.find_routes request.path

    # Raise a 404 if it's empty
    raise ART::Exceptions::NotFound.new "No route found for '#{request.method} #{request.path}'" if matching_routes.empty?

    supported_methods = [] of String

    # Iterate over each of the matched routes
    route = matching_routes.find do |r|
      action = r.payload.not_nil!

      # Create an array of supported methods for the given action
      # This'll be used if none of the routes support the request's method
      # to show the supported methods in the error messaging
      supported_methods << action.method

      # Look for an action that supports the request's method
      action.method == request.method
    end

    # Return the matched route, or raise a 405 if none of them handle the request's method
    route || raise ART::Exceptions::MethodNotAllowed.new "No route found for '#{request.method} #{request.path}': (Allow: #{supported_methods.join(", ")})"
  end
end
