# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ValidateArguments
  macro included
    macro finished
      {% verbatim do %}
        # Resolve the arguments for each service
        {%
          SERVICE_HASH.each do |service_id, definition|
            definition["parameters"].each do |_, param|
              error = nil

              # Type of the param matches param restriction
              if param["value"] != nil
                value = param["value"]
                restriction = param["resolved_restriction"]

                if restriction && restriction <= String && !value.is_a? StringLiteral
                  error = "Parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]}) expects a String but got '#{value}'."
                end

                if (s = SERVICE_HASH[value.stringify]) && !(s["class"] <= restriction)
                  error = "Parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]}) expects '#{restriction}' but" \
                          " the resolved service '#{service_id.id}' is of type '#{s["class"].id}'."
                end
              elsif !param["resolved_restriction"].nilable?
                error = "Failed to resolve value for parameter '#{param["arg"]}' of service '#{service_id.id}' (#{definition["class"]})."
              end

              param["arg"].raise error if error
            end
          end
        %}
      {% end %}
    end
  end
end
