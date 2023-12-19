# :nodoc:
#
# Service bindings overrides those defined globally, but both override autoconfigured bindings.
module Athena::DependencyInjection::ServiceContainer::ApplyBindings
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |_, definition|
            definition["parameters"].each do |name, param|
              # Typed binding
              if binding_value = BINDINGS[param["arg"].id]
                definition["bindings"][name.id] = binding_value

                # Untyped binding
              elsif binding_value = BINDINGS[param["arg"].name]
                definition["bindings"][name.id] = binding_value
              end
            end

            if ann = definition["class_ann"]
              ann.named_args.each do |k, v|
                if k.starts_with? '_'
                  definition["bindings"][k[1..-1].id] = v
                end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
