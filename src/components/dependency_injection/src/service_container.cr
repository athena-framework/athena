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
  private TAG_HASH = {} of Nil => Nil

  # # Define a hash to map alias types to a service ID.
  # private ALIAS_HASH = {} of Nil => Nil

  # # Define an array to store the IDs of all used services.
  # # I.e. that another service depends on, or is public.
  # private USED_SERVICE_IDS = [] of Nil

  # private enum Visibility
  #   # Used only via the SC.
  #   # Protected method accessor.
  #   # May be removed if unused.
  #   PRIVATE = 0

  #   # Used internally by additional types
  #   # Protected method accessor.
  #   # Never automatically removed.
  #   INTERNAL = 1

  #   # Used externally via user code.
  #   # Public method accessor.
  #   # Never automatically removed.
  #   PUBLIC = 2
  # end

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
                    {% factory_klass = factory[0] %}
                    {% factory_method = factory[1] %}

                    {% raise "Failed to register service `#{service_id.id}`.  Factory method `#{method.id}` within `#{factory_class}` is an instance method." if factory_class.instance.has_method? method %}
                    {% raise "Failed to register service `#{service_id.id}`.  Factory method `#{method.id}` within `#{factory_class}` does not exist." unless factory_class.class.has_method? method %}
                  {% end %}
                {% end %}

                {%
                  initializer = if f = factory
                                  klass.class.methods.find(&.name.==(f[1]))
                                elsif class_initializer = klass.class.methods.find(&.annotation(ADI::Inject))
                                  # Class methods with ADI::Inject should act as a factory.
                                  factory = {klass, class_initializer.name.stringify}

                                  class_initializer
                                elsif instance_initializer = klass.methods.find(&.annotation(ADI::Inject))
                                  instance_initializer
                                else
                                  klass.methods.find(&.name.==("initialize"))
                                end

                  pp initializer

                  # If no initializer was resolved, assume it's the default argless constructor.
                  initializer_args = (i = initializer) ? i.args : [] of Nil

                  SERVICE_HASH[service_id] = {
                    class:             klass.resolve,
                    class_ann:         ann,
                    factory:           factory,
                    shared:            klass.class?,
                    calls:             [] of Nil,
                    configurator:      nil,
                    tags:              [] of Nil, # TODO: Make this Hash(String, Array(Hash))
                    public:            ann[:public] != nil ? true : false,
                    decorated_service: nil,
                    bindings:          {} of Nil => Nil,
                    generics:          [] of Nil,
                    parameters:        initializer_args.map do |initializer_arg|
                      default_value = nil
                      value = nil

                      # Set the value of this parameter, but don't mark it as resolved as it could be overridden.
                      if !(dv = initializer_arg.default_value).is_a?(Nop)
                        default_value = value = dv
                      end

                      # Check for explicit service arguments, and mark parameter as resolved if defined as the service was explicitly configured to use it.
                      #
                      # Ideally we'd call into a macro def to resolve the value, because that isn't a thing yet the plan is to resolve all references within the terminal AutoWire pass.
                      if ann.named_args.keys.includes? "_#{initializer_arg.name.id}".id
                        value = ann.named_args["_#{initializer_arg.name.id}"]
                      end

                      {
                        arg:                  initializer_arg,
                        name:                 initializer_arg.name.stringify,
                        internal_name:        initializer_arg.internal_name.stringify,
                        restriction:          initializer_arg.restriction,
                        resolved_restriction: ((r = initializer_arg.restriction).is_a?(Nop) ? nil : r.resolve),
                        default_value:        default_value,
                        value:                value,
                      }
                    end,
                  }
                %}
              {% end %}
            {% end %}
          {% end %}
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

                      new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify

                      key = ""
                      char_is_part_of_key = false
                    elsif char_is_part_of_key
                      key += c
                    else
                      new_value += c
                    end
                  end

                  if !(new_value =~ /%%|%([^%\s]++)%/)
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

                          new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify

                          key = ""
                          char_is_part_of_key = false
                        elsif char_is_part_of_key
                          key += c
                        else
                          new_value += c
                        end
                      end

                      if !(new_value =~ /%%|%([^%\s]++)%/)
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

                          new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify

                          key = ""
                          char_is_part_of_key = false
                        elsif char_is_part_of_key
                          key += c
                        else
                          new_value += c
                        end
                      end

                      if !(new_value =~ /%%|%([^%\s]++)%/)
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

          {%
            pp CONFIG

            puts ""
            puts ""

            pp SERVICE_HASH

            puts ""
            puts ""

            pp TAG_HASH

            puts ""
            puts ""

            pp BINDINGS

            puts ""
            puts ""
          %}
        {% end %}
      end
    end
  end

  private module AutoWire
    macro included
      macro finished
        {% verbatim do %}
          # Resolve the arguments for each service
          {%
            SERVICE_HASH.each do |service_id, definition|
              # Use a dedicated array var such that we can use the pseudo recursion trick
              unresolved_parameters = definition[:parameters].map { |param| {param[:value], param, nil} }

              unresolved_parameters.each do |(unresolved_value, param, reference)|
                # Determine Value
                #   * DONE explicit param - _id
                #   * DONE default value - = 123
                #   * DONE Binding (Typed and untyped)
                #   * Alias
                #   * Autowire
                #   * Nilable - nil

                # Typed binding
                if binding_value = BINDINGS[param[:arg].id]
                  unresolved_value = binding_value

                  # Untyped binding
                elsif binding_value = BINDINGS[param[:arg].name.id]
                  unresolved_value = binding_value

                  # Default value
                elsif default_value = param[:default_value]
                  unresolved_value = default_value
                end

                # Resolve Value
                #   * DONE %param%
                #   * DONE @service_id
                #   * !tag
                #   * Proxy

                # Parameter reference
                if unresolved_value.is_a?(StringLiteral) && unresolved_value.starts_with?('%') && unresolved_value.ends_with?('%')
                  resolved_value = CONFIG["parameters"][unresolved_value[1..-2]]
                elsif unresolved_value.is_a?(StringLiteral) && unresolved_value.starts_with?('@')
                  service_name = unresolved_value[1..-1]
                  raise "Failed to register service '#{service_id.id}'.  Argument '#{param[:arg]}' references undefined service '#{service_name}'." unless SERVICE_HASH[service_name]
                  resolved_value = service_name.id
                elsif unresolved_value.is_a?(ArrayLiteral) || unresolved_value.is_a?(TupleLiteral)
                  # Pseudo recurse over each array element
                  resolved_value = unresolved_value
                  unresolved_value.each do |v|
                    unresolved_parameters << {v, param, {type: "array", value: resolved_value}}
                  end
                elsif unresolved_value.is_a?(HashLiteral)
                  # Pseudo recurse over each key/value pair
                  resolved_value = unresolved_value
                  unresolved_value.each do |k, v|
                    unresolved_parameters << {v, param, {type: "hash", key: k, value: resolved_value}}
                  end
                else
                  resolved_value = unresolved_value
                end

                # resolved_value = unresolved_value
                if reference && "array" == reference["type"]
                  reference[:value] << resolved_value
                elsif reference && "hash" == reference["type"]
                  reference[:value][reference[:key]] = resolved_value
                else
                  param[:value] = resolved_value
                end

                # Clear temp vars to avoid confusion
                resolved_value = nil
                unresolved_value = nil
              end

              definition[:parameters].each do |param|
                pp param
              end
            end
          %}
        {% end %}
      end
    end
  end

  private module RemoveUnusedServices
    macro included
      macro finished
        {% verbatim do %}
      {% SERVICE_HASH.each do |service_id, metadata|
           # Remove private services that are not used in other dependencies.
           if metadata[:visibility] != Visibility::PRIVATE || metadata[:alias_visibility] != Visibility::PRIVATE || USED_SERVICE_IDS.includes?(service_id.id)
           else
             SERVICE_HASH[service_id] = nil
           end
         end %}
        {% end %}
      end
    end
  end

  private module DefineGetters
    macro included
      macro finished
        {% verbatim do %}
          # Define getters for each service, if the service is public, make the getter public and also define a type based getter
          {% for service_id, metadata in SERVICE_HASH %}
            {% if metadata != nil %}
              {% service_name = metadata[:service].is_a?(StringLiteral) ? metadata[:service] : metadata[:service].name(generic_args: false) %}
              {% generics_type = "#{service_name}(#{metadata[:generics].splat})".id %}

              {% service = metadata[:generics].empty? ? metadata[:service].id : generics_type.id %}
              {% ivar_type = metadata[:generics].empty? ? metadata[:ivar_type].id : generics_type.id %}

              {% constructor_service = service %}
              {% constructor_method = "new" %}

              {% if factory = metadata[:factory] %}
                {% constructor_service = factory[0] %}
                {% constructor_method = factory[1] %}
              {% end %}

              {% if metadata[:visibility] != Visibility::PUBLIC %}protected{% end %} getter {{service_id.id}} : {{ivar_type}} { {{constructor_service}}.{{constructor_method.id}}({{metadata[:arguments].map(&.[:value]).splat}}) }

              {% if metadata[:visibility] == Visibility::PUBLIC %}
                def get(service : {{service}}.class) : {{service.id}}
                  {{service_id.id}}
                end
              {% end %}

            {% end %}
          {% end %}

          # Define getters for aliased service, if the alias is public, make the getter public and also define a type based getter
          {% for service_type, service_id in ALIAS_HASH %}
            {% metadata = SERVICE_HASH[service_id] %}

            {% if metadata != nil %}
              {% service_name = metadata[:service].is_a?(StringLiteral) ? metadata[:service] : metadata[:service].name(generic_args: false) %}
              {% type = metadata[:generics].empty? ? service_name : "#{service_name}(#{metadata[:generics].splat})".id %}

              {% if metadata[:alias_visibility] != Visibility::PUBLIC %}protected{% end %} def {{service_type.name.gsub(/::/, "_").underscore.id}} : {{type}}; {{service_id.id}}; end

              {% if metadata[:alias_visibility] == Visibility::PUBLIC %}
                def get(service : {{service_type}}.class) : {{service_type}}
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
  # * Run custom modules
  # * (TODO) Try and support annotation based configurators
  # * RegisterServices
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

  macro finished
    include RegisterServices
    include ResolveParameterPlaceholders

    include AutoWire
  end
end
