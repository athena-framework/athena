# :nodoc:
module Athena::DependencyInjection::ServiceContainer::DefineGetters
  macro included
    macro finished
      {% verbatim do %}
        {% for service_id, metadata in SERVICE_HASH %}
          {% if metadata != nil %}
            # String literal is primarily represents internal services that were created during the construction of the container.
            {% service_name = metadata[:class].is_a?(StringLiteral) ? metadata[:class].id : metadata[:class].name(generic_args: false) %}
            {% generics_type = "#{service_name}(#{metadata[:generics].splat})".id %}

            {% service = metadata[:generics].empty? ? metadata[:class].id : generics_type.id %}
            {% ivar_type = metadata[:generics].empty? ? metadata[:class].id : generics_type.id %}

            {% constructor_service = service %}
            {% constructor_method = "new" %}

            {% if factory = metadata[:factory] %}
              {% constructor_service, constructor_method = factory %}
            {% end %}

            {% if !metadata[:public] %}protected {% end %}getter {{service_id.id}} : {{ivar_type}} do
              instance = {{constructor_service}}.{{constructor_method.id}}({{
                                                                             metadata["parameters"].map do |name, param|
                                                                               str = "#{name.id}: #{param["value"]}"

                                                                               if (resolved_restriction = param["resolved_restriction"]) && resolved_restriction <= Array && param["value"].of.is_a?(Nop)
                                                                                 str += " of Union(#{resolved_restriction.type_vars.splat})"
                                                                               end

                                                                               str.id
                                                                             end.splat
                                                                           }})

              {% for call in metadata[:calls] %}
                {% method, args = call %}
                instance.{{method.id}}({{args.splat}})
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
