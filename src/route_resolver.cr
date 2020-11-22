# Registers an `ART::Action` for each action with the router.  This type is a singleton as opposed to a service to prevent all the routes from having to be redefined on each request.
class Athena::Routing::RouteResolver
  @router : Amber::Router::RouteSet(ActionBase) = Amber::Router::RouteSet(ActionBase).new

  def initialize
    {% begin %}
      # Define a hash to store registered routes.  Will be used to raise on duplicate routes.
      {% registered_routes = {} of String => String %}

      {% for klass, c_idx in Athena::Routing::Controller.all_subclasses.reject &.abstract? %}
        {% methods = klass.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) || m.annotation(Patch) || m.annotation(Link) || m.annotation(Unlink) || m.annotation(Route) } %}
        {% class_actions = klass.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) || m.annotation(Patch) || m.annotation(Link) || m.annotation(Unlink) || m.annotation(Route) } %}

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
          {% elsif d = m.annotation(Link) %}
            {% method = "LINK" %}
            {% route_def = d %}
          {% elsif d = m.annotation(Unlink) %}
            {% method = "UNLINK" %}
            {% route_def = d %}
          {% elsif d = m.annotation(Route) %}
            {% method = d[:method] || m.raise "Route action '#{klass.name}##{m.name}' is missing the HTTP method.  It was not provided via the 'method' field." %}
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

          # Build out param metadata
          {% params = [] of Nil %}

          # Process query and request params
          {% for param in [{ART::QueryParam, "ART::Params::QueryParam"}, {ART::RequestParam, "ART::Params::RequestParam"}] %}
            {% param_ann = param[0] %}
            {% param = param[1].id %}

            {% for qp in m.annotations(param_ann) %}
              {% qp.raise "Route action '#{klass.name}##{m.name}' has an ART::QueryParam annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field." unless arg_name = (qp[0] || qp[:name]) %}
              {% arg = m.args.find &.name.stringify.==(arg_name) %}
              {% qp.raise "Route action '#{klass.name}##{m.name}' has an ART::QueryParam annotation but does not have a corresponding action argument for '#{arg_name.id}'." unless arg_names.includes? arg_name %}

              {% ann_args = qp.named_args %}

              # It's possible the `requirements` field is/are `Assert` annotations,
              # resolve them into constraint objects.
              {% requirements = ann_args[:requirements] %}

              {% if requirements.is_a? RegexLiteral %}
                {% requirements = ann_args[:requirements] %}
              {% elsif requirements.is_a? Annotation %}
                {% requirement_name = requirements.stringify.gsub(/Assert::/, "").gsub(/\(.*\)/, "").tr("@[]", "") %}
                {% if constraint = AVD::Constraint.all_subclasses.reject(&.abstract?).find { |c| requirement_name == c.name(generic_args: false).split("::").last } %}
                  {% default_arg = requirements.args.empty? ? nil : requirements.args.first %}

                  {% requirements = %(#{constraint.name(generic_args: false).id}.new(#{default_arg ? "#{default_arg},".id : "".id}#{requirements.named_args.double_splat})).id %}
                {% end %}
              {% elsif requirements.is_a? ArrayLiteral %}
                {% requirements = requirements.map do |r|
                     requirement_name = r.stringify.gsub(/Assert::/, "").gsub(/\(.*\)/, "").tr("@[]", "")

                     if constraint = AVD::Constraint.all_subclasses.reject(&.abstract?).find { |c| requirement_name == c.name(generic_args: false).split("::").last }
                       default_arg = r.args.empty? ? nil : r.args.first

                       %(#{constraint.name(generic_args: false).id}.new(#{default_arg ? "#{default_arg},".id : "".id}#{r.named_args.double_splat})).id
                     end
                   end %}
              {% else %}
                {% requirements = nil %}
              {% end %}

              {% ann_args[:requirements] = requirements %}

              # Handle query param specific param converters
              {% if converter = ann_args[:converter] %}
                {% if (converter.is_a?(NamedTupleLiteral) || converter.is_a?(HashLiteral)) %}
                  {% converter_args = converter %}
                  {% converter_args[:converter] = converter_args[:name] %}
                  {% converter_args[:name] = arg_name %}
                {% else %}
                  {% converter_args = {converter: converter, name: arg_name} %}
                {% end %}

                {% param_converters << %(#{converter_args[:converter].resolve}::Configuration.new(#{converter_args.double_splat})).id %}
              {% end %}

              # TODO: Use `.delete :converter` and remove `converter` argument from `ScalarParam`.
              {% ann_args[:converter] = nil %}

              {% params << %(#{param}(#{arg.restriction}).new(
                  name: #{arg_name},
                  has_default: #{!arg.default_value.is_a?(Nop)},
                  is_nillable: #{arg.restriction.resolve.nilable?},
                  default: #{arg.default_value.is_a?(Nop) ? nil : arg.default_value},
                  #{ann_args.double_splat}
                )).id %}
            {% end %}
          {% end %}

          {% view_context = "ART::Action::ViewContext.new".id %}

          {% if view_ann = m.annotation(View) %}
            {% view_context = %(ART::Action::ViewContext.new(#{view_ann.named_args.double_splat})).id %}
          {% end %}

          {% annotation_configurations = {} of Nil => Nil %}

          {% for ann_class in ACF::CUSTOM_ANNOTATIONS %}
            {% ann_class = ann_class.resolve %}
            {% annotations = [] of Nil %}

            {% for ann in klass.annotations(ann_class) + m.annotations(ann_class) %}
              {% annotations << "#{ann_class}Configuration.new(#{ann.args.empty? ? "".id : "#{ann.args.splat},".id}#{ann.named_args.double_splat})".id %}
            {% end %}

            {% annotation_configurations[ann_class] = "(#{annotations} of ACF::AnnotationConfigurations::ConfigurationBase)".id unless annotations.empty? %}
          {% end %}

          # Add the route to the router
          @router.add(
            {{full_path}},
            Action.new(
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
              {{view_context}},
              ACF::AnnotationConfigurations.new({{annotation_configurations}} of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase)),
              ({{params}} of ART::Params::ParamInterfaceBase),
              {{klass.id}},
              {{m.return_type}},
              {{arg_types.empty? ? "typeof(Tuple.new)".id : "Tuple(#{arg_types.splat})".id}}
            ){% if constraints = route_def[:constraints] %}, {{constraints}} {% end %}
          )

          # Also add a HEAD route for GET endpoints.
          {% if method == "GET" %}
            @router.add(
              {{full_path}},
              Action.new(
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
                {{view_context}},
                ACF::AnnotationConfigurations.new({{annotation_configurations}} of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase)),
                ({{params}} of ART::Params::ParamInterfaceBase),
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

  # Attempts to resolve the *request* into an `Amber::Router::RoutedResult(Athena::Routing::ActionBase)`.
  #
  # Raises an `ART::Exceptions::NotFound` exception if a corresponding `ART::Action` could not be resolved.
  # Raises an `ART::Exceptions::MethodNotAllowed` exception if a route was matched but does not support the *request*'s method.
  def resolve(request : HTTP::Request) : Amber::Router::RoutedResult(Athena::Routing::ActionBase)
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
