# :nodoc:
#
# Loads and caches a `ART::RouteCollection` from `ART::Controllers` as well as a mapping of route names to `ATH::Action`s.
module Athena::Framework::Routing::AnnotationRouteLoader
  protected class_getter actions = Hash(String, ATH::ActionBase).new

  class_getter route_collection : ART::RouteCollection do
    collection = ART::RouteCollection.new

    {% begin %}
        # Define a hash to store registered routes. Will be used to raise on duplicate routes.
        {% registered_routes = {} of String => String %}

        {% for klass, c_idx in ATH::Controller.all_subclasses.reject &.abstract? %}
          {% methods = klass.methods.select { |m| m.annotation(ARTA::Get) || m.annotation(ARTA::Post) || m.annotation(ARTA::Put) || m.annotation(ARTA::Delete) || m.annotation(ARTA::Patch) || m.annotation(ARTA::Link) || m.annotation(ARTA::Unlink) || m.annotation(ARTA::Head) || m.annotation(ARTA::Route) } %}
          {% class_actions = klass.class.methods.select { |m| m.annotation(ARTA::Get) || m.annotation(ARTA::Post) || m.annotation(ARTA::Put) || m.annotation(ARTA::Delete) || m.annotation(ARTA::Patch) || m.annotation(ARTA::Link) || m.annotation(ARTA::Unlink) || m.annotation(ARTA::Head) || m.annotation(ARTA::Route) } %}

          # Raise compile time error if a route is defined as a class method.
          {% unless class_actions.empty? %}
            {% class_actions.first.raise "Routes can only be defined as instance methods. Did you mean '#{klass.name}##{class_actions.first.name}'?" %}
          {% end %}

          # Define global vars derived from the controller data.
          {% globals = {
               path:            "",
               localized_paths: nil,
               requirements:    {} of Nil => Nil,
               defaults:        {} of Nil => Nil,
               schemes:         [] of Nil,
               methods:         [] of Nil,
               host:            nil,
               condition:       nil,
               name:            nil,
               priority:        0,
             } %}

          {% if controller_ann = klass.annotation ARTA::Route %}
            {% if (ann_path = controller_ann[:path]) && ann_path.is_a? ArrayLiteral %}
              {% globals[:localized_paths] = ann_path %}
            {% elsif ann_path != nil %}
              {% globals[:path] = ann_path %}
            {% end %}

            # Normalize values from controller annotation to their expected locations
            {% if (value = controller_ann[:locale]) != nil %}
              {% globals[:defaults]["_locale"] = value.stringify %}
            {% end %}

            {% if (value = controller_ann[:format]) != nil %}
              {% globals[:defaults]["_format"] = value.stringify %}
            {% end %}

            {% if (value = controller_ann[:stateless]) != nil %}
              {% globals[:defaults]["_stateless"] = value.stringify %}
            {% end %}

            # Apply remaining values from controller annotation.
            {% if (value = controller_ann[:name]) != nil %}
              {% globals[:name] = value %}
            {% end %}

            {% if (value = controller_ann[:requirements]) != nil %}
              {% globals[:requirements] = value %}
            {% end %}

            {% if (value = controller_ann[:defaults]) != nil %}
              {% globals[:defaults] = value %}
            {% end %}

            {% if (value = controller_ann[:schemes]) != nil %}
              {% globals[:schemes] = value %}
            {% end %}

            {% if (value = controller_ann[:methods]) != nil %}
              {% globals[:methods] = value %}
            {% end %}

            {% if (value = controller_ann[:host]) != nil %}
              {% globals[:host] = value %}
            {% end %}

            {% if (value = controller_ann[:condition]) != nil %}
              {% globals[:condition] = value %}
            {% end %}

            {% globals[:priority] = controller_ann[:priority] || 0 %}

            # TODO: Validate requirements is a `HashLiteral`
            # TODO: Validate the condition is an `ART::Route::Condition`
          {% end %}

          %collection{c_idx} = ART::RouteCollection.new

          # Build out the routes
          {% for m in methods %}
            # Raise compile time error if the action doesn't have a return type.
            {% m.raise "Route action return type must be set for '#{klass.name}##{m.name}'." if m.return_type.is_a? Nop %}

            # Set the route_def and method(s) based on annotation.
            {%
              route_def, methods = if a = m.annotation ARTA::Get
                                     {a, ["GET"]}
                                   elsif a = m.annotation ARTA::Post
                                     {a, ["POST"]}
                                   elsif a = m.annotation ARTA::PUT
                                     {a, ["PUT"]}
                                   elsif a = m.annotation ARTA::Patch
                                     {a, ["Patch"]}
                                   elsif a = m.annotation ARTA::Delete
                                     {a, ["Delete"]}
                                   elsif a = m.annotation ARTA::Link
                                     {a, ["Link"]}
                                   elsif a = m.annotation ARTA::Unlink
                                     {a, ["Unlink"]}
                                   elsif a = m.annotation ARTA::Head
                                     {a, ["Head"]}
                                   elsif a = m.annotation ARTA::Route
                                     methods = a[:methods] || [] of Nil
                                     methods = methods.is_a?(StringLiteral) ? [methods] : methods
                                     {a, methods}
                                   end
            %}

            # Logic for creating the `ATH::Action` instances:

            # Get an array of the action's argument's types and names.
            {% arg_types = m.args.map &.restriction %}
            {% arg_names = m.args.map &.name.stringify %}

            # Build out arguments array.
            {% arguments = [] of Nil %}

            {% for arg in m.args %}
              # Raise compile time error if an action argument doesn't have a type restriction.
              {% arg.raise "Route action argument '#{klass.name}##{m.name}:#{arg.name}' must have a type restriction." if arg.restriction.is_a? Nop %}
              {% arguments << %(ATH::Arguments::ArgumentMetadata(#{arg.restriction}).new(#{arg.name.stringify}, #{arg.restriction.resolve.nilable?})).id %}
            {% end %}

            # Build out param converters array.
            {% param_converters = [] of Nil %}

            {% for converter in m.annotations(ATHA::ParamConverter) %}
              {% converter.raise "Route action '#{klass.name}##{m.name}' has an ATHA::ParamConverter annotation but is missing the argument's name. It was not provided as the first positional argument nor via the 'name' field." unless arg_name = (converter[0] || converter[:name]) %}
              {% converter.raise "Route action '#{klass.name}##{m.name}' has an ATHA::ParamConverter annotation but does not have a corresponding action argument for '#{arg_name.id}'." unless (arg = m.args.find(&.name.stringify.==(arg_name.id.stringify))) %}
              {% converter.raise "Route action '#{klass.name}##{m.name}' has an ATHA::ParamConverter annotation but is missing the converter class. It was not provided via the 'converter' field." unless converter_class = converter[:converter] %}
              {% ann_args = converter.named_args %}
              {% configuration_type = ann_args[:type_vars] != nil ? "Configuration(#{arg.restriction}, #{ann_args[:type_vars].is_a?(Path) ? ann_args[:type_vars].id : ann_args[:type_vars].splat})" : "Configuration(#{arg.restriction})" %}
              {% configuration_args = {name: arg_name.id.stringify} %}
              {% converter.named_args.to_a.select { |(k, _)| k != :type_vars }.each { |(k, v)| configuration_args[k] = v } %}
              {% param_converters << %(#{converter_class.resolve}::#{configuration_type.id}.new(#{configuration_args.double_splat})).id %}
            {% end %}

            # Build out param metadata
            {% params = [] of Nil %}

            # Process query and request params
            {% for param in [{ATHA::QueryParam, "ATH::Params::QueryParam"}, {ATHA::RequestParam, "ATH::Params::RequestParam"}] %}
              {% param_ann = param[0] %}
              {% param_class = param[1].id %}

              {% for ann in m.annotations(param_ann) %}
                {% ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation but is missing the argument's name. It was not provided as the first positional argument nor via the 'name' field." unless arg_name = (ann[0] || ann[:name]) %}
                {% arg = m.args.find &.name.stringify.==(arg_name) %}
                {% ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation but does not have a corresponding action argument for '#{arg_name.id}'." unless arg_names.includes? arg_name %}

                {% ann_args = ann.named_args %}

                # It's possible the `requirements` field is/are `Assert` annotations,
                # resolve them into constraint objects.
                {% requirements = ann_args[:requirements] %}

                {% if requirements.is_a? RegexLiteral %}
                  {% requirements = ann_args[:requirements] %}
                {% elsif requirements.is_a? Annotation %}
                  {% requirements.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation whose 'requirements' value is invalid. Expected `Assert` annotation, got '#{requirements}'." if !requirements.stringify.starts_with? "@[Assert::" %}
                  {% requirement_name = requirements.stringify.gsub(/Assert::/, "").gsub(/\(.*\)/, "").tr("@[]", "") %}
                  {% if constraint = AVD::Constraint.all_subclasses.reject(&.abstract?).find { |c| requirement_name == c.name(generic_args: false).split("::").last } %}
                    {% default_arg = requirements.args.empty? ? nil : requirements.args.first %}

                    {% requirements = %(#{constraint.name(generic_args: false).id}.new(#{default_arg ? "#{default_arg},".id : "".id}#{requirements.named_args.double_splat})).id %}
                  {% end %}
                {% elsif requirements.is_a? ArrayLiteral %}
                  {% requirements = requirements.map_with_index do |r, idx|
                       r.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation whose 'requirements' array contains an invalid value. Expected `Assert` annotation, got '#{r}' at index #{idx}." if !r.is_a?(Annotation) || !r.stringify.starts_with? "@[Assert::"

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
                  {% ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'requirements' type: '#{requirements.class_name.id}'. Only Regex, NamedTuple, or Array values are supported." unless requirements.is_a? NilLiteral %}
                {% end %}

                {% ann_args[:requirements] = requirements %}

                # Handle query param specific param converters
                {% if converter = ann_args[:converter] %}
                  {% if converter.is_a?(NamedTupleLiteral) %}
                    {% converter_args = converter %}
                    {% converter_args[:converter] = converter_args[:name] || converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter'. The converter's name was not provided via the 'name' field." %}
                    {% converter_args[:name] = arg_name %}
                  {% elsif converter.is_a? Path %}
                    {% converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter' value. Expected 'ATH::ParamConverter.class' got '#{converter.resolve.id}'." unless converter.resolve <= ATH::ParamConverter %}
                    {% converter_args = {converter: converter.resolve, name: arg_name} %}
                  {% else %}
                    {% converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter' type: '#{converter.class_name.id}'. Only NamedTuples, or the converter class are supported." %}
                  {% end %}

                  {% configuration_type = converter_args[:type_vars] != nil ? "Configuration(#{arg.restriction}, #{converter_args[:type_vars].is_a?(Path) ? converter_args[:type_vars].id : converter_args[:type_vars].splat})" : "Configuration(#{arg.restriction})" %}
                  {% configuration_args = {name: converter_args[:name]} %}
                  {% converter_args.to_a.select { |(k, _)| k != :type_vars }.each { |(k, v)| configuration_args[k] = v } %}

                  {% param_converters << %(#{converter_args[:converter].resolve}::#{configuration_type.id}.new(#{configuration_args.double_splat})).id %}
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
              # MyApp::UserController#new_user # => my_app_user_controller_new_user
              {% route_name = "#{klass.name.stringify.split("::").join("_").underscore.downcase.id}_#{m.name.id}" %}
            {% end %}

            # Setup the `ATH::Action` and set the `_controller` default so future logic knows which method it should handle it by default.
            {% globals[:defaults]["_controller"] = action_name = "#{klass.name}##{m.name}" %}
            @@actions[{{action_name}}] = ATH::Action.new(
              action: ->{
                # If the controller is not registered as a service, simply new one up
                # TODO: Replace this with a compiler pass after https://github.com/crystal-lang/crystal/pull/9091 is released
                {% if ann = klass.annotation(ADI::Register) %}
                  {% klass.raise "Controller service '#{klass.id}' must be declared as public." unless ann[:public] %}
                  %instance = ADI.container.get({{klass.id}})
                {% else %}
                  %instance = {{klass.id}}.new
                {% end %}

                ->%instance.{{m.name.id}}{% unless m.args.empty? %}({{arg_types.splat}}){% end %}
              },
              arguments: {{arguments.empty? ? "Array(ATH::Arguments::ArgumentMetadata(Nil)).new".id : arguments}},
              param_converters: {{param_converters.empty? ? "Tuple.new".id : "{#{param_converters.splat}}".id}},
              annotation_configurations: ACF::AnnotationConfigurations.new({{annotation_configurations}} of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase)),
              params: ({{params}} of ATH::Params::ParamInterface),
              _controller: {{klass.id}},
              _return_type: {{m.return_type}},
              _arg_types: {{arg_types.empty? ? "typeof(Tuple.new)".id : "Tuple(#{arg_types.splat})".id}}
            )

            {%
              paths = {} of Nil => Nil
              defaults = {} of Nil => Nil
              requirements = {} of Nil => Nil

              # Resolve `ART::Route` data from the route annotation and globals.

              globals[:defaults].each { |k, v| defaults[k] = v }
              globals[:requirements].each { |k, v| requirements[k] = v }

              m.args.reject(&.default_value.is_a?(Nop)).each { |a| defaults[a.name.stringify] = a.default_value }

              if ann_defaults = route_def[:defaults]
                ann_defaults.each { |k, v| defaults[k] = v }
              end

              if ann_requirements = route_def[:requirements]
                ann_requirements.each { |k, v| requirements[k] = v }
              end

              schemes = (globals[:schemes] + (route_def[:schemes] || [] of Nil)).uniq
              methods = (globals[:methods] + methods).uniq
              priority = route_def[:priority] || globals[:priority]
              host = route_def[:host] || globals[:host]

              condition = route_def[:condition] || globals[:condition]
              priority = route_def[:priority] || globals[:priority]

              unless (path = route_def[:localized_paths] || route_def[0] || route_def[:path])
                m.raise "Route action '#{klass.name}##{m.name}' is annotated as a '#{methods.id}' route but is missing the path."
              end

              prefix = globals[:localized_paths] || globals[:path]

              # Process path/prefix values to a hash of paths that should be created.
              if path.is_a? HashLiteral
                if !prefix.is_a? HashLiteral
                  path.each { |locale, locale_path| paths[locale] = "#{prefix.id}#{locale_path.id}" }
                elsif !(missing = prefix.keys.reject { |k| path[k] }).empty?
                  m.raise "Route action '#{klass.name}##{m.name}' is missing paths for locale(s) '#{missing.join(",").id}'."
                else
                  path.each do |locale, locale_path|
                    if prefix[locale] == nil
                      m.raise "Route action '#{klass.name}##{m.name}' with locale '#{locale.id}' is missing a corresponding prefix in class '#{klass.name}'."
                    end

                    paths[locale] = "#{prefix[locale].id}#{locale_path.id}"
                  end
                end
              elsif prefix.is_a? HashLiteral
                prefix.each { |locale, locale_prefix| paths[locale] = "#{locale_prefix.id}#{path.id}" }
              else
                paths["_default"] = "#{prefix.id}#{path.id}"
              end
            %}

            {% for locale, path in paths %}
              {%
                r_name = route_name
                r_defaults = defaults
                r_requirements = requirements

                if locale != "_default"
                  r_defaults["_locale"] = locale
                  r_requirements["_locale"] = "Regex.escape(#{locale})".id
                  r_defaults["_canonical_route"] = r_name
                  r_name = "#{route_name.id}.#{locale.id}"
                end
              %}

              %route{path} = ART::Route.new(
                path: {{path}},
                defaults: {{r_defaults.empty? ? "Hash(String, String?).new".id : r_defaults}},
                requirements: {{r_requirements}} of String => Regex | String,
                host: {{host}},
                schemes: {{schemes.empty? ? nil : schemes}},
                methods: {{methods.empty? ? nil : methods}},
                condition: {{condition}}
              )

              %collection{c_idx}.add({{r_name}}, %route{path}, {{priority}})
            {% end %}
          {% end %}

          collection.add %collection{c_idx}
        {% end %}
        {{debug}}
      {% end %}

    collection
  end
end
