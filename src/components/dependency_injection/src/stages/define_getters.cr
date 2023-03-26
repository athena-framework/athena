# :nodoc:
module Athena::DependencyInjection::ServiceContainer::DefineGetters
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
