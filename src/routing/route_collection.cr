# Wrapper around all the registered routes of an application.
# Routes are cached as a class variables since they're immutable once the program has been built.
class Athena::Routing::RouteCollection
  include Enumerable({String, Athena::Routing::ActionBase})
  include Iterable({String, Athena::Routing::ActionBase})

  @@routes : Hash(String, ART::ActionBase)?

  protected def self.routes : Hash(String, ART::ActionBase)
    @@routes ||= begin
      routes = Hash(String, ART::ActionBase).new

      {% begin %}
        # Define a hash to store registered routes.  Will be used to raise on duplicate routes.
        {% registered_routes = {} of String => String %}

        {% for klass, c_idx in Athena::Routing::Controller.all_subclasses.reject &.abstract? %}
          {% methods = klass.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) || m.annotation(Patch) || m.annotation(Link) || m.annotation(Unlink) || m.annotation(Head) || m.annotation(Route) } %}
          {% class_actions = klass.class.methods.select { |m| m.annotation(Get) || m.annotation(Post) || m.annotation(Put) || m.annotation(Delete) || m.annotation(Patch) || m.annotation(Link) || m.annotation(Unlink) || m.annotation(Head) || m.annotation(Route) } %}

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
            {% elsif d = m.annotation(Head) %}
              {% method = "HEAD" %}
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
              {% param_class = param[1].id %}

              {% for ann in m.annotations(param_ann) %}
                {% ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation but is missing the argument's name.  It was not provided as the first positional argument nor via the 'name' field." unless arg_name = (ann[0] || ann[:name]) %}
                {% arg = m.args.find &.name.stringify.==(arg_name) %}
                {% ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation but does not have a corresponding action argument for '#{arg_name.id}'." unless arg_names.includes? arg_name %}

                {% ann_args = ann.named_args %}

                # It's possible the `requirements` field is/are `Assert` annotations,
                # resolve them into constraint objects.
                {% requirements = ann_args[:requirements] %}

                {% if requirements.is_a? RegexLiteral %}
                  {% requirements = ann_args[:requirements] %}
                {% elsif requirements.is_a? Annotation %}
                  {% requirements.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation whose 'requirements' value is invalid.  Expected `Assert` annotation, got '#{requirements}'." if !requirements.stringify.starts_with? "@[Assert::" %}
                  {% requirement_name = requirements.stringify.gsub(/Assert::/, "").gsub(/\(.*\)/, "").tr("@[]", "") %}
                  {% if constraint = AVD::Constraint.all_subclasses.reject(&.abstract?).find { |c| requirement_name == c.name(generic_args: false).split("::").last } %}
                    {% default_arg = requirements.args.empty? ? nil : requirements.args.first %}

                    {% requirements = %(#{constraint.name(generic_args: false).id}.new(#{default_arg ? "#{default_arg},".id : "".id}#{requirements.named_args.double_splat})).id %}
                  {% end %}
                {% elsif requirements.is_a? ArrayLiteral %}
                  {% requirements = requirements.map_with_index do |r, idx|
                       r.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation whose 'requirements' array contains an invalid value.  Expected `Assert` annotation, got '#{r}' at index #{idx}." if !r.is_a?(Annotation) || !r.stringify.starts_with? "@[Assert::"

                       requirement_name = r.stringify.gsub(/Assert::/, "").gsub(/\(.*\)/, "").tr("@[]", "")

                       # Use the name of the annotation as a way to match it up with the constraint until there is a better way.
                       if constraint = AVD::Constraint.all_subclasses.reject(&.abstract?).find { |c| requirement_name == c.name(generic_args: false).split("::").last }
                         # Don't support default args of nested annotations due to complexity,
                         # can revisit when macro code can be shared.
                         default_arg = r.args.empty? ? nil : r.args.first

                         %(#{constraint.name(generic_args: false).id}.new(#{default_arg ? "#{default_arg},".id : "".id}#{r.named_args.double_splat})).id
                       end
                     end %}
                {% else %}
                  {% ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'requirements' type: '#{requirements.class_name.id}'.  Only Regex, NamedTuple, or Array values are supported." unless requirements.is_a? NilLiteral %}
                {% end %}

                {% ann_args[:requirements] = requirements %}

                # Handle query param specific param converters
                {% if converter = ann_args[:converter] %}
                  {% if converter.is_a?(NamedTupleLiteral) %}
                    {% converter_args = converter %}
                    {% converter_args[:converter] = converter_args[:name] || converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter'. The converter's name was not provided via the 'name' field." %}
                    {% converter_args[:name] = arg_name %}
                  {% elsif converter.is_a? Path %}
                    {% converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter' value.  Expected 'ART::ParamConverterInterface.class' got '#{converter.resolve.id}'." unless converter.resolve <= ART::ParamConverterInterface %}
                    {% converter_args = {converter: converter.resolve, name: arg_name} %}
                  {% else %}
                    {% converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter' type: '#{converter.class_name.id}'.  Only NamedTuples, or the converter class are supported." %}
                  {% end %}

                  {% param_converters << %(#{converter_args[:converter].resolve}::Configuration.new(#{converter_args.double_splat})).id %}
                {% end %}

                # Non strict parameters must be nilable or have a default value.
                {% if ann_args[:strict] == false && !arg.restriction.resolve.nilable? && arg.default_value.is_a?(Nop) %}
                  {% ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with `strict: false` but the related action argument is not nilable nor has a default value." %}
                {% end %}

                # TODO: Use `.delete :converter` and remove `converter` argument from `ScalarParam`.
                {% ann_args[:converter] = nil %}

                {% params << %(#{param_class}(#{arg.restriction}).new(
                    name: #{arg_name},
                    has_default: #{!arg.default_value.is_a?(Nop)},
                    is_nilable: #{arg.restriction.resolve.nilable?},
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

            {% if name = route_def[:name] %}
              {% route_name = name %}
            {% else %}
              {% route_name = "#{klass.name.stringify.split("::").last.underscore.downcase.id}_#{m.name.id}" %}
            {% end %}

            {% constraints = {} of Nil => Nil %}

            {% if constraint = route_def[:constraints] %}
              {% for key, value in constraint %}
                {% constraints[key.id.stringify] = value %}
              {% end %}
            {% end %}

            # Add the route to the router
            routes[{{route_name}}] = %action{route_name} = Action.new(
              action: ->{
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
              name: {{route_name}},
              method: {{method}},
              path: {{full_path}},
              constraints: ({{constraints}} of String => Regex),
              arguments: {{arguments.empty? ? "Array(ART::Arguments::ArgumentMetadata(Nil)).new".id : arguments}},
              param_converters: ({{param_converters}} of ART::ParamConverterInterface::ConfigurationInterface),
              view_context: {{view_context}},
              annotation_configurations: ACF::AnnotationConfigurations.new({{annotation_configurations}} of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase)),
              params: ({{params}} of ART::Params::ParamInterface),
              _controller: {{klass.id}},
              _return_type: {{m.return_type}},
              _arg_types: {{arg_types.empty? ? "typeof(Tuple.new)".id : "Tuple(#{arg_types.splat})".id}}
            )

            # Add a HEAD route for GET requests
            {% if "GET" == method %}
              routes[{{route_name + "_head"}}] = %action{route_name}.copy_with method: "HEAD", name: {{route_name + "_head"}}
            {% end %}
          {% end %}
        {% end %}
      {% end %}

      routes
    end
  end

  # Yields the name and `ART::Action` object for each registered route.
  def each : Nil
    self.routes.each do |k, v|
      yield({k, v})
    end
  end

  # Returns an `Iterator` for each registered route.
  def each
    self.routes.each
  end

  # Returns the routes hash.
  def routes : Hash(String, ART::ActionBase)
    self.class.routes
  end

  # Returns the `ART::Action` with the provided *name*.
  #
  # Raises a `KeyError` if a route with the provided *name* does not exist.
  def get(name : String) : ART::ActionBase
    self.routes.fetch(name) { raise KeyError.new "Unknown route: '#{name}'." }
  end

  # Returns the `ART::Action` with the provided *name*, or `nil` if it does not exist.
  def get?(name : String) : ART::ActionBase?
    self.routes[name]?
  end
end
