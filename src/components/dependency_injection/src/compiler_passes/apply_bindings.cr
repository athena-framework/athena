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
              set_value = false

              # Typed binding
              BINDINGS.keys.select(&.is_a?(TypeDeclaration)).each do |key|
                if key.var.id == param["arg"].name.id && (type = param["resolved_restriction"]) && key.type.resolve >= type
                  set_value = true
                  definition["bindings"][name.id] = BINDINGS[key]
                end
              end

              # Untyped binding
              BINDINGS.keys.select(&.!.is_a?(TypeDeclaration)).each do |key|
                if key.id == param["arg"].name.id && !set_value
                  # Only set a value if one was not already set via a typed binding
                  definition["bindings"][name.id] = BINDINGS[key]
                end
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
