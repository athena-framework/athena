# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ResolveGenerics
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            ann = definition["class_ann"]
            generics = ann.args
            klass = definition["class"]

            if !klass.type_vars.empty? && (ann && !ann[:name])
              klass.raise "Failed to register services for '#{klass}'. Generic services must explicitly provide a name."
            end

            if !klass.type_vars.empty? && generics.empty?
              klass.raise "Failed to register service '#{service_id.id}'. Generic services must provide the types to use via the 'generics' field."
            end

            if klass.type_vars.size != generics.size
              klass.raise "Failed to register service '#{service_id.id}'. Expected #{klass.type_vars.size} generics types got #{generics.size}."
            end

            definition["generics"] = generics
          end
        %}
      {% end %}
    end
  end
end
