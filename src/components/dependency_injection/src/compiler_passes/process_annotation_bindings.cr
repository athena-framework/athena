# :nodoc:
#
# Applies bindings from the register annotation.
module Athena::DependencyInjection::ServiceContainer::ProcessAnnotationBindings
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |_, definition|
            annotations = definition["class"].annotations ADI::Register

            # If there is only 1 ann, it's going to be this def,
            # otherwise we need to extract the name off the annotation to update the proper definition.
            # Depends on the `RegisterServices` logic that ensures there is a `name` property on all annotations when there is more than one.
            if 1 == annotations.size
              annotations.first.named_args.each do |k, v|
                if k.starts_with? '_'
                  definition["bindings"][k[1..-1]] = v
                end
              end
            else
              annotations.each do |ann|
                ann.named_args.each do |k, v|
                  if k.starts_with? '_'
                    SERVICE_HASH[ann["name"]]["bindings"][k[1..-1]] = v
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
