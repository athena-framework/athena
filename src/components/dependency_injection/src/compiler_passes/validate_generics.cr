# :nodoc:
#
# Validate generic services.
module Athena::DependencyInjection::ServiceContainer::ValidateGenerics
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            klass = definition["class"]
            generics = definition["generics"]

            if !klass.type_vars.empty? && generics.empty?
              klass.raise "Failed to register service '#{service_id.id}'. Generic services must provide the types to use via the 'generics' field."
            end

            if klass.type_vars.size != generics.size
              klass.raise "Failed to register service '#{service_id.id}'. Expected #{klass.type_vars.size} generics types got #{generics.size}."
            end
          end
        %}
      {% end %}
    end
  end
end
