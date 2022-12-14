# :nodoc:
#
# Loads and caches a `ART::RouteCollection` from `ART::Controllers` as well as a mapping of route names to `ATH::Action`s.
module Athena::Framework::Routing::AnnotationRouteLoader
  protected class_getter actions = Hash(String, ATH::ActionBase).new

  class_getter route_collection : ART::RouteCollection do
    populate_collection
  end

  # :nodoc:
  #
  # Abstracts the logic to create the `ART::RouteCollection` such that it can be tested in a more performant way.
  macro populate_collection(base = nil)
    collection = ART::RouteCollection.new

    {% begin %}
      {% for klass, c_idx in (base ? [base.resolve] : ATH::Controller.all_subclasses.reject &.abstract?) %}
        # Define global vars derived from the controller data.
        {%
          methods = klass.methods.select { |m| m.annotation(ARTA::Get) || m.annotation(ARTA::Post) || m.annotation(ARTA::Put) || m.annotation(ARTA::Delete) || m.annotation(ARTA::Patch) || m.annotation(ARTA::Link) || m.annotation(ARTA::Unlink) || m.annotation(ARTA::Head) || m.annotation(ARTA::Route) }
          class_actions = klass.class.methods.select { |m| m.annotation(ARTA::Get) || m.annotation(ARTA::Post) || m.annotation(ARTA::Put) || m.annotation(ARTA::Delete) || m.annotation(ARTA::Patch) || m.annotation(ARTA::Link) || m.annotation(ARTA::Unlink) || m.annotation(ARTA::Head) || m.annotation(ARTA::Route) }

          # Raise compile time error if a route is defined as a class method.
          unless class_actions.empty?
            class_actions.first.raise "Routes can only be defined as instance methods. Did you mean '#{klass.name}##{class_actions.first.name}'?"
          end

          globals = {
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
          }

          if controller_ann = klass.annotation ARTA::Route
            if (ann_path = controller_ann[:path]) && ann_path.is_a? HashLiteral
              globals[:localized_paths] = ann_path
            elsif ann_path != nil
              if !ann_path.is_a?(StringLiteral) && !ann_path.is_a?(HashLiteral)
                ann_path.raise "Route action '#{klass.name}' expects a 'StringLiteral | HashLiteral(StringLiteral, StringLiteral)' for its 'ARTA::Route#path' field, but got a '#{ann_path.class_name.id}'."
              end
              globals[:path] = ann_path
            end

            if (value = controller_ann[:defaults]) != nil
              value.raise "Route action '#{klass.name}' expects a 'HashLiteral(StringLiteral, _)' for its 'ARTA::Route#defaults' field, but got a '#{value.class_name.id}'." unless value.is_a? HashLiteral
              globals[:defaults] = value
            end

            if (value = controller_ann[:locale]) != nil
              value.raise "Route action '#{klass.name}' expects a 'StringLiteral' for its 'ARTA::Route#locale' field, but got a '#{value.class_name.id}'." unless value.is_a? StringLiteral
              globals[:defaults]["_locale"] = value
            end

            if (value = controller_ann[:format]) != nil
              value.raise "Route action '#{klass.name}' expects a 'StringLiteral' for its 'ARTA::Route#format' field, but got a '#{value.class_name.id}'." unless value.is_a? StringLiteral
              globals[:defaults]["_format"] = value
            end

            if controller_ann[:stateless] != nil
              value = controller_ann[:stateless]

              value.raise "Route action '#{klass.name}' expects a 'BoolLiteral' for its 'ARTA::Route#stateless' field, but got a '#{value.class_name.id}'." unless value.is_a? BoolLiteral
              globals[:defaults]["_stateless"] = value
            end

            if (value = controller_ann[:name]) != nil
              value.raise "Route action '#{klass.name}' expects a 'StringLiteral' for its 'ARTA::Route#name' field, but got a '#{value.class_name.id}'." unless value.is_a? StringLiteral
              globals[:name] = value
            end

            if (value = controller_ann[:requirements]) != nil
              value.raise "Route action '#{klass.name}' expects a 'HashLiteral(StringLiteral, StringLiteral | RegexLiteral)' for its 'ARTA::Route#requirements' field, but got a '#{value.class_name.id}'." unless value.is_a? HashLiteral
              globals[:requirements] = value
            end

            if (value = controller_ann[:schemes]) != nil
              if !value.is_a?(StringLiteral) && !value.is_a?(ArrayLiteral) && !value.is_a?(TupleLiteral)
                value.raise "Route action '#{klass.name}' expects a 'StringLiteral | Enumerable(StringLiteral)' for its 'ARTA::Route#schemes' field, but got a '#{value.class_name.id}'."
              end

              globals[:schemes] = value
            end

            if (value = controller_ann[:methods]) != nil
              if !value.is_a?(StringLiteral) && !value.is_a?(ArrayLiteral) && !value.is_a?(TupleLiteral)
                value.raise "Route action '#{klass.name}' expects a 'StringLiteral | Enumerable(StringLiteral)' for its 'ARTA::Route#methods' field, but got a '#{value.class_name.id}'."
              end

              globals[:methods] = value
            end

            if (value = controller_ann[:host]) != nil
              if !value.is_a?(StringLiteral) && !value.is_a?(RegexLiteral)
                value.raise "Route action '#{klass.name}' expects a 'StringLiteral | RegexLiteral' for its 'ARTA::Route#host' field, but got a '#{value.class_name.id}'."
              end

              globals[:host] = value
            end

            if (value = controller_ann[:condition]) != nil
              if !value.is_a?(Call) || value.receiver.resolve != ART::Route::Condition
                value.raise "Route action '#{klass.name}' expects an 'ART::Route::Condition' for its 'ARTA::Route#condition' field, but got a '#{value.class_name.id}'."
              end

              globals[:condition] = value
            end

            if (value = controller_ann[:priority]) != nil
              if !value.is_a?(NumberLiteral)
                value.raise "Route action '#{klass.name}' expects a 'NumberLiteral' for its 'ARTA::Route#priority' field, but got a '#{value.class_name.id}'."
              end

              globals[:priority] = value
            end
          end
        %}

        %collection{c_idx} = ART::RouteCollection.new

        # Build out the routes
        {% for m in methods %}
          # Raise compile time error if the action doesn't have a return type.
          {% if m.return_type.is_a? Nop %}
            {% m.raise "Route action return type must be set for '#{klass.name}##{m.name}'." %}
          {% end %}

          {%
            arguments = [] of Nil
            param_converters = [] of Nil
            params = [] of Nil
            annotation_configurations = {} of Nil => Nil

            # Logic for creating the `ATH::Action` instances:

            arg_types = m.args.map &.restriction
            arg_names = m.args.map &.name.stringify

            # Set the route_def and method(s) based on annotation.
            route_def, methods = if a = m.annotation ARTA::Get
                                   {a, ["GET"]}
                                 elsif a = m.annotation ARTA::Post
                                   {a, ["POST"]}
                                 elsif a = m.annotation ARTA::Put
                                   {a, ["PUT"]}
                                 elsif a = m.annotation ARTA::Patch
                                   {a, ["PATCH"]}
                                 elsif a = m.annotation ARTA::Delete
                                   {a, ["DELETE"]}
                                 elsif a = m.annotation ARTA::Link
                                   {a, ["LINK"]}
                                 elsif a = m.annotation ARTA::Unlink
                                   {a, ["UNLINK"]}
                                 elsif a = m.annotation ARTA::Head
                                   {a, ["HEAD"]}
                                 elsif a = m.annotation ARTA::Route
                                   methods = a[:methods] || [] of Nil

                                   if !methods.is_a?(StringLiteral) && !methods.is_a?(ArrayLiteral) && !methods.is_a?(TupleLiteral)
                                     a.raise "Route action '#{klass.name}##{m.name}' expects a 'StringLiteral | ArrayLiteral | TupleLiteral' for its 'ARTA::Route#methods' field, but got a '#{methods.class_name.id}'."
                                   end

                                   methods = methods.is_a?(StringLiteral) ? [methods] : methods
                                   {a, methods}
                                 end

            # Disallow `methods` field when _NOT_ using `ARTA::Route`.
            if !m.annotation(ARTA::Route) && route_def[:methods] != nil
              route_def.raise "Route action '#{klass.name}##{m.name}' cannot change the required methods when _NOT_ using the 'ARTA::Route' annotation."
            end

            # Process controller action arguments.
            m.args.each do |arg|
              arg.raise "Route action argument '#{klass.name}##{m.name}:#{arg.name}' must have a type restriction." if arg.restriction.is_a? Nop
              arguments << %(ATH::Arguments::ArgumentMetadata(#{arg.restriction}).new(#{arg.name.stringify}, #{!arg.default_value.is_a? Nop}, #{arg.default_value.is_a?(Nop) ? nil : arg.default_value})).id
            end

            # Process param converters
            m.annotations(ATHA::ParamConverter).each do |converter|
              unless arg_name = (converter[0] || converter[:name])
                converter.raise "Route action '#{klass.name}##{m.name}' has an ATHA::ParamConverter annotation but is missing the argument's name. It was not provided as the first positional argument nor via the 'name' field."
              end

              unless (arg = m.args.find(&.name.stringify.==(arg_name.id.stringify)))
                converter.raise "Route action '#{klass.name}##{m.name}' has an ATHA::ParamConverter annotation but does not have a corresponding action argument for '#{arg_name.id}'."
              end

              unless converter_class = converter[:converter]
                converter.raise "Route action '#{klass.name}##{m.name}' has an ATHA::ParamConverter annotation but is missing the converter class. It was not provided via the 'converter' field."
              end

              ann_args = converter.named_args
              configuration_type = ann_args[:type_vars] != nil ? "Configuration(#{arg.restriction}, #{ann_args[:type_vars].is_a?(Path) ? ann_args[:type_vars].id : ann_args[:type_vars].splat})" : "Configuration(#{arg.restriction})"
              configuration_args = {name: arg_name.id.stringify}
              converter.named_args.to_a.select { |(k, _)| k != :type_vars }.each { |(k, v)| configuration_args[k] = v }
              param_converters << %(#{converter_class.resolve}::#{configuration_type.id}.new(#{configuration_args.double_splat})).id
            end

            # Process custom annotation types
            ACF::CUSTOM_ANNOTATIONS.each do |ann_class|
              ann_class = ann_class.resolve
              annotations = [] of Nil

              (klass.annotations(ann_class) + m.annotations(ann_class)).each do |ann|
                annotations << "#{ann_class}Configuration.new(#{ann.args.empty? ? "".id : "#{ann.args.splat},".id}#{ann.named_args.double_splat})".id
              end

              annotation_configurations[ann_class] = "(#{annotations} of ACF::AnnotationConfigurations::ConfigurationBase)".id unless annotations.empty?
            end

            # Process query and request params
            [{ATHA::QueryParam, "ATH::Params::QueryParam".id}, {ATHA::RequestParam, "ATH::Params::RequestParam".id}].each do |(param_ann, param_class)|
              m.annotations(param_ann).each do |ann|
                unless arg_name = (ann[0] || ann[:name])
                  ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation but is missing the argument's name. It was not provided as the first positional argument nor via the 'name' field."
                end

                arg = m.args.find &.name.stringify.==(arg_name)

                unless arg_names.includes? arg_name
                  ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation but does not have a corresponding action argument for '#{arg_name.id}'."
                end

                ann_args = ann.named_args

                requirements = ann_args[:requirements]

                if requirements.is_a? RegexLiteral
                  requirements = ann_args[:requirements]
                elsif requirements.is_a? Annotation
                  if !requirements.stringify.starts_with? "@[Assert::"
                    requirements.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation whose 'requirements' value is invalid. Expected `Assert` annotation, got '#{requirements}'."
                  end

                  requirement_name = requirements.stringify.gsub(/Assert::/, "").gsub(/\(.*\)/, "").tr("@[]", "")
                  if constraint = AVD::Constraint.all_subclasses.reject(&.abstract?).find { |c| requirement_name == c.name(generic_args: false).split("::").last }
                    default_arg = requirements.args.empty? ? nil : requirements.args.first
                    requirements = %(#{constraint.name(generic_args: false).id}.new(#{default_arg ? "#{default_arg},".id : "".id}#{requirements.named_args.double_splat})).id
                  end
                elsif requirements.is_a? ArrayLiteral
                  requirements = requirements.map_with_index do |r, idx|
                    if !r.is_a?(Annotation) || !r.stringify.starts_with? "@[Assert::"
                      r.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation whose 'requirements' array contains an invalid value. Expected `Assert` annotation, got '#{r}' at index #{idx}."
                    end

                    requirement_name = r.stringify.gsub(/Assert::/, "").gsub(/\(.*\)/, "").tr("@[]", "")

                    # Use the name of the annotation as a way to match it up with the constraint until there is a better way.
                    if constraint = AVD::Constraint.all_subclasses.reject(&.abstract?).find { |c| requirement_name == c.name(generic_args: false).split("::").last }
                      # Don't support default args of nested annotations due to complexity,
                      # can revisit when macro code can be shared.
                      default_arg = r.args.empty? ? nil : r.args.first

                      %(#{constraint.name(generic_args: false).id}.new(#{default_arg ? "#{default_arg},".id : "".id}#{r.named_args.double_splat})).id
                    end
                  end
                elsif !requirements.is_a? NilLiteral
                  ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'requirements' type: '#{requirements.class_name.id}'. Only Regex, NamedTuple, or Array values are supported."
                end

                ann_args[:requirements] = requirements

                # Handle query param specific param converters
                if converter = ann_args[:converter]
                  if converter.is_a?(NamedTupleLiteral)
                    converter_args = converter
                    converter_args[:converter] = converter_args[:name] || converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter'. The converter's name was not provided via the 'name' field."
                    converter_args[:name] = arg_name
                  elsif converter.is_a? Path
                    unless converter.resolve <= ATH::ParamConverter
                      converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter' value. Expected 'ATH::ParamConverter.class' got '#{converter.resolve.id}'."
                    end

                    converter_args = {converter: converter.resolve, name: arg_name}
                  else
                    converter.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with an invalid 'converter' type: '#{converter.class_name.id}'. Only NamedTuples, or the converter class are supported."
                  end

                  configuration_type = converter_args[:type_vars] != nil ? "Configuration(#{arg.restriction}, #{converter_args[:type_vars].is_a?(Path) ? converter_args[:type_vars].id : converter_args[:type_vars].splat})" : "Configuration(#{arg.restriction})"
                  configuration_args = {name: converter_args[:name]}
                  converter_args.to_a.select { |(k, _)| k != :type_vars }.each { |(k, v)| configuration_args[k] = v }
                  param_converters << %(#{converter_args[:converter].resolve}::#{configuration_type.id}.new(#{configuration_args.double_splat})).id
                end

                # Non strict parameters must be nilable or have a default value.
                if ann_args[:strict] == false && !arg.restriction.resolve.nilable? && arg.default_value.is_a?(Nop)
                  ann.raise "Route action '#{klass.name}##{m.name}' has an #{param_ann} annotation with `strict: false` but the related action argument is not nilable nor has a default value."
                end

                # TODO: Use `.delete :converter` and remove `converter` argument from `ScalarParam`.
                ann_args[:converter] = nil

                params << %(#{param_class}(#{arg.restriction}).new(
                  name: #{arg_name},
                  has_default: #{!arg.default_value.is_a?(Nop)},
                  is_nilable: #{arg.restriction.resolve.nilable?},
                  default: #{arg.default_value.is_a?(Nop) ? nil : arg.default_value},
                  #{ann_args.double_splat}
                )).id
              end
            end

            # Setup the `ATH::Action` and set the `_controller` default so future logic knows which method it should handle it by default.
            route_name = if (value = route_def[:name]) != nil
                           if !value.is_a?(StringLiteral)
                             value.raise "Route action '#{klass.name}##{m.name}' expects a 'StringLiteral' for its '#{route_def.name}#name' field, but got a '#{value.class_name.id}'."
                           end

                           value
                         else
                           # MyApp::UserController#new_user # => my_app_user_controller_new_user
                           "#{klass.name.stringify.split("::").join("_").underscore.downcase.id}_#{m.name.id}"
                         end

            if globals_name = globals[:name]
              route_name = "#{globals_name.id}_#{route_name.id}"
            end

            globals[:defaults]["_controller"] = action_name = "#{klass.name}##{m.name}"
          %}

          {% if base == nil %}
            @@actions[{{action_name}}] = ATH::Action.new(
              action: Proc({{arg_types.empty? ? "typeof(Tuple.new)".id : "Tuple(#{arg_types.splat})".id}}, {{m.return_type}}).new do |arguments|
                # If the controller is not registered as a service, simply new one up,
                # otherwise fetch it directly from the SC.
                {% if klass.annotation(ADI::Register) %}
                  %instance = ADI.container.get({{klass.id}})
                {% else %}
                  %instance = {{klass.id}}.new
                {% end %}

                %instance.{{m.name.id}} *arguments
              end,
              arguments: {{arguments.empty? ? "Array(ATH::Arguments::ArgumentMetadata(Nil)).new".id : arguments}},
              param_converters: {{param_converters.empty? ? "Tuple.new".id : "{#{param_converters.splat}}".id}},
              annotation_configurations: ACF::AnnotationConfigurations.new({{annotation_configurations}} of ACF::AnnotationConfigurations::Classes => Array(ACF::AnnotationConfigurations::ConfigurationBase)),
              params: ({{params}} of ATH::Params::ParamInterface),
              _controller: {{klass.id}},
              _return_type: {{m.return_type}},
            )
          {% end %}

            {%
              paths = {} of Nil => Nil
              defaults = {} of Nil => Nil
              requirements = {} of Nil => Nil

              # Resolve `ART::Route` data from the route annotation and globals.

              globals[:defaults].each { |k, v| defaults[k] = v }
              globals[:requirements].each { |k, v| requirements[k] = v }

              if (value = route_def[:locale]) != nil
                value.raise "Route action '#{klass.name}##{m.name}' expects a 'StringLiteral' for its '#{route_def.name}#locale' field, but got a '#{value.class_name.id}'." unless value.is_a? StringLiteral
                defaults["_locale"] = value
              end

              if (value = route_def[:format]) != nil
                value.raise "Route action '#{klass.name}##{m.name}' expects a 'StringLiteral' for its '#{route_def.name}#format' field, but got a '#{value.class_name.id}'." unless value.is_a? StringLiteral
                defaults["_format"] = value
              end

              if route_def[:stateless] != nil
                value = route_def[:stateless]

                value.raise "Route action '#{klass.name}##{m.name}' expects a 'BoolLiteral' for its '#{route_def.name}#stateless' field, but got a '#{value.class_name.id}'." unless value.is_a? BoolLiteral
                defaults["_stateless"] = value
              end
              if ann_defaults = route_def[:defaults]
                unless ann_defaults.is_a? HashLiteral
                  ann_defaults.raise "Route action '#{klass.name}##{m.name}' expects a 'HashLiteral(StringLiteral, _)' for its '#{route_def.name}#defaults' field, but got a '#{ann_defaults.class_name.id}'."
                end

                ann_defaults.each { |k, v| defaults[k] = v }
              end

              if ann_requirements = route_def[:requirements]
                unless ann_requirements.is_a? HashLiteral
                  ann_requirements.raise "Route action '#{klass.name}##{m.name}' expects a 'HashLiteral(StringLiteral, StringLiteral | RegexLiteral)' for its '#{route_def.name}#requirements' field, but got a '#{ann_requirements.class_name.id}'."
                end

                ann_requirements.each do |k, v|
                  requirements[k] = if v.is_a?(StringLiteral) || v.is_a?(RegexLiteral)
                                      v
                                    else
                                      "#{v}.to_s".id
                                    end
                end
              end

              if (value = route_def[:host]) != nil
                if !value.is_a?(StringLiteral) && !value.is_a?(RegexLiteral)
                  value.raise "Route action '#{klass.name}##{m.name}' expects a 'StringLiteral | RegexLiteral' for its '#{route_def.name}#host' field, but got a '#{value.class_name.id}'."
                end
              end

              if (value = route_def[:priority]) != nil
                if !value.is_a?(NumberLiteral)
                  value.raise "Route action '#{klass.name}##{m.name}' expects a 'NumberLiteral' for its '#{route_def.name}#priority' field, but got a '#{value.class_name.id}'."
                end
              end

              if (value = route_def[:condition]) != nil
                if !value.is_a?(Call) || value.receiver.resolve != ART::Route::Condition
                  value.raise "Route action '#{klass.name}##{m.name}' expects an 'ART::Route::Condition' for its '#{route_def.name}#condition' field, but got a '#{value.class_name.id}'."
                end
              end

              schemes = (globals[:schemes] + (route_def[:schemes] || [] of Nil)).uniq
              methods = (globals[:methods] + methods).uniq
              priority = route_def[:priority] || globals[:priority]
              host = route_def[:host] || globals[:host]

              condition = route_def[:condition] || globals[:condition]
              priority = route_def[:priority] || globals[:priority]

              unless (path = route_def[:localized_paths] || route_def[0] || route_def[:path])
                m.raise "Route action '#{klass.name}##{m.name}' is missing its path."
              end

              if !path.is_a?(StringLiteral) && !path.is_a?(HashLiteral)
                path.raise "Route action '#{klass.name}##{m.name}' expects a 'StringLiteral | HashLiteral(StringLiteral, StringLiteral)' for its '#{route_def.name}#path' field, but got a '#{path.class_name.id}'."
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
                      m.raise "Route action '#{klass.name}##{m.name}' is missing a corresponding route prefix for the '#{locale.id}' locale."
                    end

                    paths[locale] = "#{prefix[locale].id}#{locale_path.id}"
                  end
                end
              elsif prefix.is_a? HashLiteral
                prefix.each { |locale, locale_prefix| paths[locale] = "#{locale_prefix.id}#{path.id}" }
              else
                paths["_default"] = "#{prefix.id}#{path.id}"
              end

              m.args.each do |arg|
                paths.each do |_, pth|
                  pth.split('/').each do |p|
                    if p.starts_with?("{#{arg.name}") && defaults[arg.name.stringify] == nil && !arg.default_value.is_a?(Nop) && p =~ /\{\w+(?:<.*?>)?\}/
                      defaults[arg.name.stringify] = arg.default_value
                    end
                  end
                end
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
      {% end %}

      ART.compile collection

      collection
  end
end
