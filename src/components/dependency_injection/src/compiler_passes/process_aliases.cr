# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ProcessAliases
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            if al = definition["aliases"]
              aliases = al.is_a?(ArrayLiteral) ? al : [al]

              aliases.each do |a|
                id_key = a.resolve.name.gsub(/::/, "_").underscore
                alias_service_id = id_key.is_a?(StringLiteral) ? id_key : id_key.stringify

                SERVICE_HASH[a.resolve] = {
                  class:      definition["class"].resolve,
                  class_ann:  definition["class_ann"],
                  tags:       {} of Nil => Nil,
                  parameters: definition["parameters"],
                  bindings:   {} of Nil => Nil,
                  generics:   [] of Nil,

                  alias_service_id:   alias_service_id,
                  aliased_service_id: service_id,
                  alias:              true,
                }
              end
            end
          end
        %}
      {% end %}
    end
  end
end
