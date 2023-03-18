# Where the instantiated services live.
#
# If a service is public, a getter based on the service's name as well as its type is defined.  Otherwise, services are only available via constructor DI.
#
# TODO: Reduce the amount of duplication when [this issue](https://github.com/crystal-lang/crystal/pull/9091) is resolved.
class Athena::DependencyInjection::ServiceContainer
  # Define a hash to store services while the container is being built
  # Key is the ID of the service and the value is another hash containing its arguments, type, etc.
  private SERVICE_HASH = {} of Nil => Nil

  # Define a hash to store the service ids for each tag.
  #
  # Tag Name, service_id, array attributes
  # Hash(String, Hash(String, Array(NamedTuple)))
  private TAG_HASH = {} of Nil => Nil

  private module RegisterServices
    macro included
      macro finished
        {% verbatim do %}
          # Register each service in the hash along with some related metadata.
          {% for klass in Object.all_subclasses.select &.annotation(ADI::Register) %}
            {% if (annotations = klass.annotations(ADI::Register)) && !annotations.empty? && !klass.abstract? %}
              # Raise a compile time exception if multiple services are based on this type, and not all of them specify a `name`.
              {% if annotations.size > 1 && !annotations.all? &.[:name] %}
                {% klass.raise "Failed to register services for '#{klass}'.  Services based on this type must each explicitly provide a name." %}
              {% end %}

              {% for ann in annotations %}
                {% ann = ann %}

                # Use the service name defined within the annotation, otherwise fallback on FQN snake cased
                {% id_key = ann[:name] || klass.name.gsub(/::/, "_").underscore %}
                {% service_id = id_key.is_a?(StringLiteral) ? id_key : id_key.stringify %}

                {% factory = nil %}

                {% if factory_ann = ann[:factory] %}
                  {% factory = if factory_ann.is_a? StringLiteral
                                 {klass.resolve, factory_ann}
                               elsif factory_ann.is_a? TupleLiteral
                                 {factory_ann[0].resolve, factory_ann[1]}
                               end %}

                  # Validate the factory method exists and is a class method
                  {% if factory %}
                    {% factory_class, factory_method = factory %}

                    {% raise "Failed to register service `#{service_id.id}`.  Factory method `#{method.id}` within `#{factory_class}` is an instance method." if factory_class.instance.has_method? factory_method %}
                    {% raise "Failed to register service `#{service_id.id}`.  Factory method `#{method.id}` within `#{factory_class}` does not exist." unless factory_class.class.has_method? factory_method %}
                  {% end %}
                {% end %}

                {%
                  initializer = if f = factory
                                  (f.first).class.methods.find(&.name.==(f[1]))
                                elsif class_initializer = klass.class.methods.find(&.annotation(ADI::Inject))
                                  # Class methods with ADI::Inject should act as a factory.
                                  factory = {klass, class_initializer.name.stringify}

                                  class_initializer
                                elsif instance_initializer = klass.methods.find(&.annotation(ADI::Inject))
                                  instance_initializer
                                else
                                  klass.methods.find(&.name.==("initialize"))
                                end

                  # If no initializer was resolved, assume it's the default argless constructor.
                  initializer_args = (i = initializer) ? i.args : [] of Nil
                  parameters = {} of Nil => Nil

                  initializer_args.each_with_index do |initializer_arg, idx|
                    default_value = nil
                    value = nil

                    # Set the value of this parameter, but don't mark it as resolved as it could be overridden.
                    if !(dv = initializer_arg.default_value).is_a?(Nop)
                      default_value = value = dv
                    end

                    parameters[initializer_arg.name.id.stringify] = {
                      arg:                  initializer_arg,
                      name:                 initializer_arg.name.stringify,
                      idx:                  idx,
                      internal_name:        initializer_arg.internal_name.stringify,
                      restriction:          initializer_arg.restriction,
                      resolved_restriction: ((r = initializer_arg.restriction).is_a?(Nop) ? nil : r.resolve),
                      default_value:        default_value,
                      value:                value || default_value,
                    }
                  end

                  SERVICE_HASH[service_id] = {
                    class:             klass.resolve,
                    class_ann:         ann,
                    factory:           factory,
                    shared:            klass.class?,
                    calls:             [] of Nil,
                    configurator:      nil,
                    tags:              {} of Nil => Nil,
                    public:            ann[:public] == true,
                    decorated_service: nil,
                    bindings:          {} of Nil => Nil,
                    generics:          [] of Nil,
                    parameters:        parameters,
                  }

                  if a = ann[:alias]
                    id_key = a.resolve.name.gsub(/::/, "_").underscore
                    alias_service_id = id_key.is_a?(StringLiteral) ? id_key : id_key.stringify

                    SERVICE_HASH[a.resolve] = {
                      class:      klass.resolve,
                      parameters: {} of Nil => Nil,
                      bindings:   {} of Nil => Nil,
                      generics:   [] of Nil,
                    }
                  end
                %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      end
    end
  end

  private module Autoconfigure
    macro included
      macro finished
        {% verbatim do %}
          {%
            SERVICE_HASH.each do |service_id, definition|
              tags = definition["class_ann"]["tags"] || [] of Nil

              if !tags.is_a? ArrayLiteral
                definition["class_ann"].raise "Tags for '#{service_id.id}' must be an 'ArrayLiteral', got '#{tags.class_name.id}'."
              end

              auto_configuration_tags = nil

              AUTO_CONFIGURATIONS.keys.select(&.>=(definition["class"])).each do |key|
                auto_configuration = AUTO_CONFIGURATIONS[key]

                if (v = auto_configuration["bind"]) != nil
                  v.each do |k, v|
                    definition["bindings"][k.id.stringify] = v
                  end
                end

                if (v = auto_configuration["public"]) != nil
                  definition["public"] = v
                end

                if (v = auto_configuration["tags"]) != nil
                  if !v.is_a? ArrayLiteral
                    definition["class_ann"].raise "Tags for '#{service_id.id}' must be an 'ArrayLiteral', got '#{tags.class_name.id}'."
                  end

                  tags += v
                end

                # TODO: Configurator?
              end

              # Process both autoconfiguration tags and normal tags here to keep the logic somewhat centralized.

              definition_tags = definition["tags"]

              tags.each do |tag|
                name, attributes = if tag.is_a?(StringLiteral)
                                     {tag, {} of Nil => Nil}
                                   elsif tag.is_a?(Path)
                                     {tag.resolve.id.stringify, {} of Nil => Nil}
                                   elsif tag.is_a?(NamedTupleLiteral) || tag.is_a?(HashLiteral)
                                     tag.raise "Failed to register service `#{service_id.id}`.  All tags must have a name." unless tag[:name]

                                     # Resolve a constant to its value if used as a tag name
                                     if tag["name"].is_a? Path
                                       tag["name"] = tag[""].resolve
                                     end

                                     attributes = {} of Nil => Nil

                                     # TODO: Replace this with `#delete`...
                                     tag.each do |k, v|
                                       attributes[k.id.stringify] = v unless k.id.stringify == "name"
                                     end

                                     {tag["name"], attributes}
                                   else
                                     tag.raise "Tag '#{tag}'. A tag must be a StringLiteral or NamedTupleLiteral not #{tag.class_name.id}."
                                   end

                definition_tags[name] = [] of Nil if definition_tags[name] == nil
                definition_tags[name] << attributes

                TAG_HASH[name] = [] of Nil if TAG_HASH[name] == nil
                TAG_HASH[name] << {service_id, definition, attributes}
              end

              pp definition
            end
          %}
        {% end %}
      end
    end
  end

  private module ResolveGenerics
    macro included
      macro finished
        {% verbatim do %}
          {%
            SERVICE_HASH.each do |service_id, definition|
              ann = definition["class_ann"]
              generics = ann.args
              klass = definition["class"]

              if !klass.type_vars.empty? && (ann && !ann[:name])
                klass.raise "Failed to register services for '#{klass}'.  Generic services must explicitly provide a name."
              end

              if !klass.type_vars.empty? && generics.empty?
                klass.raise "Failed to register service '#{service_id.id}'.  Generic services must provide the types to use via the 'generics' field."
              end

              if klass.type_vars.size != generics.size
                klass.raise "Failed to register service '#{service_id.id}'.  Expected #{klass.type_vars.size} generics types got #{generics.size}."
              end

              definition["generics"] = generics
            end
          %}
        {% end %}
      end
    end
  end

  private module ResolveParameterPlaceholders
    macro included
      macro finished
        {% verbatim do %}

          # I hate how much code it takes to do this, but is quite cool I got it to work.
          # WTB https://github.com/crystal-lang/crystal/issues/8835 :((
          #
          # The purpose of this module is to resolve placeholder values within various parameters.
          # E.g. `"https://%app.domain%/"` => `"https://example.com/"`.
          #
          # It is assumed that any user added parameters via another module have already happened.
          # Parameters added after this module will not be resolved.
          #
          # The macro API is quite limited compared to the normal stdlib API.
          # As such we do not have access to recursion, nor do we have the ability to use a regex to extract the parameter name from the value.
          # These together makes this code quite crazy to grok.
          #
          # We first create an array that we can iterate over, using a somewhat custom variation of `NamedTupleLiteral#to_a` that also includes the collection the related key/value are located at.
          # The first tuple in this array is for the configuration parameters are these are most likely going to need to be resolved first anyway.
          # We then add the rest of the tuples, all using the `CONFIG` hash as the root collection.
          # Having this array is important since arrays are reference types, we can push more things to it while looping thru it to have somewhat pseudo recursion; this will be important later.
          # Next, we iterate over each key/value/collection grouping in the array, checking if the value is a supported type:
          #
          # * A string literal that has `%%` in it, or any text in between two `%`.
          # * A hash literal where one of the value of that hash has a `%%` in it, or any text in between two `%`.
          #   * NOTE: NamedTuple literals are _NOT_ supported as a terminal value, use a HashLiteral instead
          # * An array/tuple literal whose value has a `%%` in it, or any text in between two `%`.
          #
          # In each case, in order to extract the parameter name from the string, we iterate over the characters that make up the string, building out the key based on the chars between the `%`s.
          # This is done via the following algorithm:
          #
          # 1. If the current char is a `%` and next char is a `%` we skip as that implies the `%%` context which is an escaped `%`.
          # 2. If this is the first time we saw a `%` and the current char is a `%` and we're either at the beginning, or the previous char wasn't a `%`,
          #    then we know we're not starting to parse the parameter key.
          # 3. If we're in parameter key parsing mode and the current char is a `%` we know we're done and can resolve this key's placeholder
          #    by first looking up the parameter's value within `CONFIG["parameters"]`,
          #    ensuring its a string, resetting the key (since there may be multiple placeholders), finally exiting parameter key parsing mode.
          # 4. If we're in parameter key parsing mode, but the current character is not `%`, we append this character to the `key` variable
          # 5. If we're not in parameter key parsing mode, we append this character to the `new_value` variable, which represents the rebuilt value with placeholders resolved.
          #
          # After all this we'll either end up with a fully resolved value, denoted by it not longer matching the regex, or a value that needs additional placeholders resolved,
          # e.g. because the parameters it depends on are not yet resolved, or was resolved to a value that contained other yet to be resolved values.
          # In either case, if the value is not fully resolved we push the same key, but the new value _BACK_ into the original array we're iterating over along with the collection they belong to.
          # This will cause it to loop again and start the process all over on the previously resolved value;
          # this will run until either they're all resolved, or an unknown parameter is encountered.
          #
          # The process is also essentially the same for array/hash literals, but operating on the sub-hash's value or the array's elements.
          # But are two main differences:
          #
          # 1.The path to the value we're updating is no longer _just_ `CONFIG["parameters"][k]`, but the key/index of the collection.
          # 2. In the re-process context, we're pushing the whole collection, as the value, which should match the left hand side of the assignment above it, minus the sub-key/index.

          {%
            to_process = CONFIG.to_a.map { |(k, v)| {k, v, CONFIG, [k]} }

            to_process.each do |(k, v, h, stack)|
              if v.is_a?(NamedTupleLiteral)
                v.to_a.each do |(sk, sv)|
                  to_process << {sk, sv, v, stack + [sk]}
                end
              else
                if v.is_a?(StringLiteral) && v =~ /%%|%([^%\s]++)%/
                  key = ""
                  char_is_part_of_key = false

                  new_value = ""

                  chars = v.chars

                  chars.each_with_index do |c, idx|
                    if c == '%' && chars[idx + 1] == '%'
                      # Do nothing as we'll just add the next char
                    elsif !char_is_part_of_key && c == '%' && (idx == 0 || chars[idx - 1] != '%')
                      char_is_part_of_key = true
                    elsif char_is_part_of_key && c == '%'
                      resolved_value = CONFIG["parameters"][key]

                      if resolved_value == nil
                        path = "#{stack[0]}"

                        stack[1..].each do |p|
                          path += "[#{p}]"
                        end

                        key.raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}' referenced unknown parameter '#{key.id}'."
                      end

                      if new_value.empty?
                        new_value = resolved_value
                      else
                        new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                      end

                      key = ""
                      char_is_part_of_key = false
                    elsif char_is_part_of_key
                      key += c
                    else
                      new_value += c
                    end
                  end

                  if !new_value.is_a?(StringLiteral) || (new_value.is_a?(StringLiteral) && !(new_value =~ /%%|%([^%\s]++)%/))
                    h[k] = new_value
                  else
                    to_process << {k, new_value, h, stack}
                  end
                elsif v.is_a?(HashLiteral)
                  v.each do |sk, sv|
                    if sv.is_a?(StringLiteral) && sv =~ /%%|%([^%\s]++)%/
                      key = ""
                      char_is_part_of_key = false

                      new_value = ""

                      chars = sv.chars

                      chars.each_with_index do |c, c_idx|
                        if c == '%' && chars[c_idx + 1] == '%'
                          # Do nothing as we'll just add the next char
                        elsif !char_is_part_of_key && c == '%' && (c_idx == 0 || chars[c_idx - 1] != '%')
                          char_is_part_of_key = true
                        elsif char_is_part_of_key && c == '%'
                          resolved_value = CONFIG["parameters"][key]

                          if resolved_value == nil
                            path = "#{stack[0]}"

                            stack[1..].each do |p|
                              path += "[#{p}]"
                            end

                            h[k][sk].raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}[#{sk}]' referenced unknown parameter '#{key.id}'."
                          end

                          if new_value.empty?
                            new_value = resolved_value
                          else
                            new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                          end

                          key = ""
                          char_is_part_of_key = false
                        elsif char_is_part_of_key
                          key += c
                        else
                          new_value += c
                        end
                      end

                      if !new_value.is_a?(StringLiteral) || (new_value.is_a?(StringLiteral) && !(new_value =~ /%%|%([^%\s]++)%/))
                        h[k][sk] = new_value
                      else
                        to_process << {k, h[k], h, stack}
                      end
                    end
                  end
                elsif v.is_a?(ArrayLiteral) || v.is_a?(TupleLiteral)
                  v.each_with_index do |av, a_idx|
                    if av.is_a?(StringLiteral) && av =~ /%%|%([^%\s]++)%/
                      key = ""
                      char_is_part_of_key = false

                      new_value = ""

                      chars = av.chars

                      chars.each_with_index do |c, c_idx|
                        if c == '%' && chars[c_idx + 1] == '%'
                          # Do nothing as we'll just add the next char
                        elsif !char_is_part_of_key && c == '%' && (c_idx == 0 || chars[c_idx - 1] != '%')
                          char_is_part_of_key = true
                        elsif char_is_part_of_key && c == '%'
                          resolved_value = CONFIG["parameters"][key]

                          if resolved_value == nil
                            path = "#{stack[0]}"

                            stack[1..].each do |p|
                              path += "[#{p}]"
                            end

                            h[k][a_idx].raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}[#{a_idx}]' referenced unknown parameter '#{key.id}'."
                          end

                          if new_value.empty?
                            new_value = resolved_value
                          else
                            new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                          end

                          key = ""
                          char_is_part_of_key = false
                        elsif char_is_part_of_key
                          key += c
                        else
                          new_value += c
                        end
                      end

                      if !new_value.is_a?(StringLiteral) || (new_value.is_a?(StringLiteral) && !(new_value =~ /%%|%([^%\s]++)%/))
                        h[k][a_idx] = new_value
                      else
                        to_process << {k, h[k], h}
                      end
                    end
                  end
                end
              end
            end
          %}
        {% end %}
      end
    end
  end

  private module ApplyGlobalBindings
    macro included
      macro finished
        {% verbatim do %}
          # Resolve the arguments for each service
          {%
            SERVICE_HASH.each do |_, definition|
              definition["parameters"].each do |name, param|
                # Typed binding
                if binding_value = BINDINGS[param["arg"].id]
                  definition["bindings"][name] = binding_value

                  # Untyped binding
                elsif binding_value = BINDINGS[param["arg"].name]
                  definition["bindings"][name] = binding_value
                end
              end
            end
          %}
        {% end %}
      end
    end
  end

  private module ApplyServiceBindings
    macro included
      macro finished
        {% verbatim do %}
          {%
            SERVICE_HASH.each do |_, definition|
              if ann = definition["class_ann"]
                ann.named_args.each do |k, v|
                  if k.starts_with? '_'
                    definition["bindings"][k[1..-1].id.stringify] = v
                  end
                end
              end
            end
          %}
        {% end %}
      end
    end
  end

  private module AutoWire
    macro included
      macro finished
        {% verbatim do %}
          {%
            SERVICE_HASH.each do |_, definition|
              definition["parameters"].each do |name, param|
                param_resolved_restriction = param["resolved_restriction"]
                resolved_services = [] of Nil

                # Otherwise resolve possible services based on type
                SERVICE_HASH.each do |id, s_metadata|
                  if (type = param_resolved_restriction) &&
                     (
                       s_metadata["class"] <= type ||
                       (type < ADI::Proxy && s_metadata["class"] <= type.type_vars.first.resolve)
                     )
                    resolved_services << id
                  end
                end

                resolved_service = nil

                if resolved_services.size == 1
                  resolved_service = resolved_services[0]
                elsif rs = resolved_services.find(&.==(name.id))
                  resolved_service = rs
                elsif (s = SERVICE_HASH[(param_resolved_restriction && param_resolved_restriction < ADI::Proxy ? param_resolved_restriction.type_vars.first.resolve : param_resolved_restriction)])
                  resolved_service = s["class"].name.gsub(/::/, "_").underscore
                end

                if resolved_service
                  param["value"] = if param["resolved_restriction"] < ADI::Proxy
                                     "ADI::Proxy.new(#{resolved_service}, ->#{resolved_service.id})".id
                                   else
                                     resolved_service.id
                                   end
                end
              end
            end
          %}
        {% end %}
      end
    end
  end

  private module ResolveValues
    macro included
      macro finished
        {% verbatim do %}
          {%
            SERVICE_HASH.each do |service_id, definition|
              # Use a dedicated array var such that we can use the pseudo recursion trick
              parameters = definition["parameters"].map { |_, param| {param["value"], param, nil} }

              parameters.each do |(unresolved_value, param, reference)|
                # Parameter reference
                if unresolved_value.is_a?(StringLiteral) && unresolved_value.starts_with?('%') && unresolved_value.ends_with?('%')
                  resolved_value = CONFIG["parameters"][unresolved_value[1..-2]]

                  # Service reference
                elsif unresolved_value.is_a?(StringLiteral) && unresolved_value.starts_with?('@')
                  service_name = unresolved_value[1..-1]
                  raise "Failed to register service '#{service_id.id}'.  Argument '#{param["arg"]}' references undefined service '#{service_name.id}'." unless SERVICE_HASH[service_name]
                  resolved_value = service_name.id

                  # Array, could contain nested references
                elsif unresolved_value.is_a?(ArrayLiteral) || unresolved_value.is_a?(TupleLiteral)
                  # Pseudo recurse over each array element
                  resolved_value = unresolved_value

                  unresolved_value.each_with_index do |v, idx|
                    parameters << {v, param, {type: "array", key: idx, value: resolved_value}}
                  end

                  # Hash, could contain nested references
                elsif unresolved_value.is_a?(HashLiteral)
                  # Pseudo recurse over each key/value pair
                  resolved_value = unresolved_value

                  unresolved_value.each do |k, v|
                    parameters << {v, param, {type: "hash", key: k, value: resolved_value}}
                  end
                  # Bound value, only apply if no value is already set
                elsif unresolved_value == nil && (bv = definition["bindings"][param["name"]]) # && (bv != unresolved_value)
                  resolved_value = nil

                  parameters << {bv, param, {type: "scalar"}}

                  # Scalar value
                else
                  resolved_value = unresolved_value
                end

                if reference && ("array" == reference["type"] || "hash" == reference["type"])
                  reference["value"][reference[:key]] = resolved_value
                else
                  param["value"] = resolved_value
                end

                # Clear temp vars to avoid confusion
                resolved_value = nil
                unresolved_value = nil
              end
            end
          %}
        {% end %}
      end
    end
  end

  private module ValidateArguments
    macro included
      macro finished
        {% verbatim do %}
          # Resolve the arguments for each service
          {%
            SERVICE_HASH.each do |service_id, definition|
              definition["parameters"].each do |_, param|
                error = nil

                # Type of the param matches param restriction
                if param["value"] != nil
                  value = param["value"]
                  restriction = param["resolved_restriction"]

                  if restriction && restriction <= String && !value.is_a? StringLiteral
                    error = "Parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]}) expects a String but got '#{value}'."
                  end

                  if (s = SERVICE_HASH[value.stringify]) && !(s["class"] <= restriction)
                    error = "Parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]}) expects '#{restriction}' but" \
                            " the resolved service '#{service_id.id}' is of type '#{s["class"].id}'."
                  end
                elsif !param["resolved_restriction"].nilable?
                  error = "Failed to resolve value for parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]})."
                end

                param["arg"].raise error if error
              end
            end
          %}
        {% end %}
      end
    end
  end

  private module DefineGetters
    macro included
      macro finished
        {% verbatim do %}
          {% for service_id, metadata in SERVICE_HASH %}
            {% if metadata != nil && metadata["class_ann"] != nil %}
              {% service_name = metadata[:class].is_a?(StringLiteral) ? metadata[:class] : metadata[:class].name(generic_args: false) %}
              {% generics_type = "#{service_name}(#{metadata[:generics].splat})".id %}

              {% service = metadata[:generics].empty? ? metadata[:class].id : generics_type.id %}
              {% ivar_type = metadata[:generics].empty? ? metadata[:class].id : generics_type.id %}

              {% constructor_service = service %}
              {% constructor_method = "new" %}

              {% if factory = metadata[:factory] %}
                {% constructor_service, constructor_method = factory %}
              {% end %}

              {% if !metadata[:public] %}protected {% end %}getter {{service_id.id}} : {{ivar_type}} do
                {{constructor_service}}.{{constructor_method.id}}({{
                                                                    metadata["parameters"].map do |name, param|
                                                                      "#{name.id}: #{param["value"]}".id
                                                                    end.splat
                                                                  }})
              end

              {% if metadata[:public] %}
                def get(service : {{service}}.class) : {{service.id}}
                  {{service_id.id}}
                end
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      end
    end
  end

  # Args on annotation are like direct named args that apply to that singular service
  # Bindings apply to 0..n services
  # Autowiring apply to 0..n services. Terminal state

  # # Algorithm
  #
  # ## PreOptimization
  # * RegisterServices
  # * ResolveGenerics
  # * Run custom modules
  # * (TODO) Try and support annotation based configurators
  #
  # ## Optimization
  # * Resolve parameter placeholders
  # * Bindings
  # * Autowire
  # * Run custom modules
  #
  # ## Removing
  # * Run custom modules
  # * RemoveUnusedServices
  #
  # ## PostRemoving
  # * DefineGetters

  # TODO: Ability to know if a service's args weren't resolved

  # Determine Value
  #   * DONE explicit param - _id
  #   * DONE default value - = 123
  #   * DONE Binding (Typed and untyped)
  #     * Ann > Global > autoconfigure
  #   * Alias
  #   * Autowire
  #   * Nilable - nil

  # Resolve Value
  #   * DONE %param%
  #   * DONE @service_id
  #   * !tag
  #   * DONE Proxy

  macro finished
    # Global pre-optimization modules
    include RegisterServices
    include Autoconfigure
    include ResolveGenerics

    # Custom modules to register new services, explicitly set arguments, or modify them in some other way

    # Global optimization modules that prepare the services for usage
    # Resolve arguments, parameters, and ensure validity of each service
    include ResolveParameterPlaceholders
    include ApplyGlobalBindings
    include ApplyServiceBindings
    include AutoWire
    include ResolveValues
    include ValidateArguments

    # Custom modules to further modify services

    # Global cleanup services
    # include RemoveUnusedServices

    # Global codegen things that create things within the container instances, such as the getters for each service
    include DefineGetters

    # ?? Custom modules to codegen/cleanup things?
  end
end
