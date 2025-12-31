# :nodoc:
module Athena::DependencyInjection::ServiceContainer::DefineGetters
  macro included
    macro finished
      {% verbatim do %}
        {% for service_id, metadata in SERVICE_HASH %}
          {% if metadata != nil && !metadata["inlined"] %}
            # String literal primarily represents internal services created during container construction.
            {% service_name = metadata[:class].is_a?(StringLiteral) ? metadata[:class].id : metadata[:class].name(generic_args: false) %}
            {% generics_type = "#{service_name}(#{metadata[:generics].splat})".id %}

            {% service = metadata[:generics].empty? ? metadata[:class].id : generics_type.id %}
            {% ivar_type = metadata[:generics].empty? ? metadata[:class].id : generics_type.id %}

            {% constructor_service = service %}
            {% constructor_method = "new" %}

            {% if factory = metadata[:factory] %}
              {% constructor_service, constructor_method = factory %}
            {% end %}

            {%
              __nil = nil

              # Collect inline setup code from inlined dependencies
              inline_setups = [] of Nil
              metadata["parameters"].each do |_, param|
                value = param["value"]

                # Check direct service reference
                value_str = value.id.stringify
                dep = SERVICE_HASH[value_str]
                if dep && dep["inlined"] && dep["inline_setup"]
                  inline_setups << dep["inline_setup"]
                end

                # Check array elements for service references
                if value.is_a?(ArrayLiteral)
                  value.each do |v|
                    v_str = v.id.stringify
                    dep = SERVICE_HASH[v_str]
                    if dep && dep["inlined"] && dep["inline_setup"]
                      inline_setups << dep["inline_setup"]
                    end
                  end
                end
              end

              # Collect inline setups from call arguments
              if calls = metadata["calls"]
                calls.each do |call|
                  method, args = call
                  if args
                    args.each do |arg|
                      arg_dep = SERVICE_HASH[arg.stringify]
                      if arg_dep && arg_dep["inlined"] && arg_dep["inline_setup"]
                        inline_setups << arg_dep["inline_setup"]
                      end
                    end
                  end
                end
              end
            %}

            {% if !metadata[:public] %}protected {% end %}getter {{service_id.id}} : {{ivar_type}} do
              {% for setup in inline_setups %}
                {{setup.id}}
              {% end %}

              instance = {{constructor_service}}.{{constructor_method.id}}({{
                                                                             metadata["parameters"].map do |name, param|
                                                                               value = param["value"]
                                                                               value_str = value.id.stringify

                                                                               # Check if this parameter references an inlined service
                                                                               dep = SERVICE_HASH[value_str]
                                                                               if dep && dep["inlined"] && dep["inline_var"]
                                                                                 "#{name.id}: #{dep["inline_var"].id}".id
                                                                               elsif value.is_a?(ArrayLiteral)
                                                                                 # Handle array with potential inlined services
                                                                                 elements = value.map do |v|
                                                                                   v_str = v.id.stringify
                                                                                   v_dep = SERVICE_HASH[v_str]
                                                                                   if v_dep && v_dep["inlined"] && v_dep["inline_var"]
                                                                                     v_dep["inline_var"].id
                                                                                   else
                                                                                     v
                                                                                   end
                                                                                 end
                                                                                 str = "#{name.id}: [#{elements.splat}]"
                                                                                 if (resolved_restriction = param["resolved_restriction"]) && resolved_restriction <= Array && (value.of.is_a?(Nop) || elements.empty?)
                                                                                   str += " of Union(#{resolved_restriction.type_vars.splat})"
                                                                                 end
                                                                                 str.id
                                                                               else
                                                                                 "#{name.id}: #{value}".id
                                                                               end
                                                                             end.splat
                                                                           }})

              {% for call in metadata[:calls] %}
                {% method, args = call %}
                {%
                  transformed_args = args.map do |arg|
                    arg_dep = SERVICE_HASH[arg.stringify]
                    if arg_dep && arg_dep["inlined"] && arg_dep["inline_var"]
                      arg_dep["inline_var"].id
                    else
                      arg
                    end
                  end
                %}
                instance.{{method.id}}({{transformed_args.splat}})
              {% end %}

              instance
            end

            {% if metadata[:public] %}
              def get(service : {{service}}.class) : {{service.id}}
                {{service_id.id}}
              end
            {% end %}
          {% end %}
        {% end %}

        {% for alias_name, metadata in ALIASES %}
          {% if metadata["public"] %}
            # String alias maps to a service => service alias so we just need a method with the alias' name.
            {% if alias_name.is_a?(StringLiteral) %}
              def {{alias_name.id}} : {{SERVICE_HASH[metadata["id"]]["class"].id}}
                {{metadata["id"].id}}
              end
            # TypeNode alias maps to an interface => service alias, so we need an override of `#get` pinned to the interface type.
            {% else %}
              def get(service : {{alias_name.id}}.class) : {{alias_name.id}}
                {{metadata["id"].id}}
              end
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    end
  end
end
