# :nodoc:
#
# Removes services that are never used (not public and zero references).
module Athena::DependencyInjection::ServiceContainer::RemoveUnusedServices
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_REFERENCES.each do |service_id, ref_info|
            # Only remove if: not public AND no references
            if ref_info["public"] == false && ref_info["count"] == 0
              SERVICE_HASH[service_id] = nil
            end
          end
        %}
      {% end %}
    end
  end
end
