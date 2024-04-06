# :nodoc:
#
# Processes each service definition to determine their constructor parameters.
# Also ensures manually wired up services have full and proper initializer information
module Athena::DependencyInjection::ServiceContainer::ProcessParameters
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, definition|
            klass = definition["class"]

            initializer = if f = definition["factory"]
                            f.first.class.methods.find(&.name.==(f[1]))
                          elsif specific_initializer = klass.methods.find(&.annotation(ADI::Inject))
                            specific_initializer
                          else
                            klass.methods.find(&.name.==("initialize"))
                          end

            # If no initializer was resolved, assume it's the default argless constructor.
            initializer_args = (i = initializer) ? i.args : [] of Nil

            parameters = definition["parameters"]

            initializer_args.each_with_index do |initializer_arg, idx|
              param_name = initializer_arg.name.id.stringify
              default_value = nil

              # Inherit value if it was already configured on the param
              value = if (p = parameters[param_name]) && p.keys.map(&.stringify).includes?("value")
                        p["value"]
                      else
                        nil
                      end

              # Set the default value is there is one.
              if !(dv = initializer_arg.default_value).is_a?(Nop)
                default_value = dv
              end

              parameters[initializer_arg.name.id.stringify] = {
                declaration:          initializer_arg,
                name:                 initializer_arg.name.stringify,
                idx:                  idx,
                internal_name:        initializer_arg.internal_name.stringify,
                restriction:          initializer_arg.restriction,
                resolved_restriction: ((r = initializer_arg.restriction).is_a?(Nop) ? nil : r.resolve),
                default_value:        default_value,
                value:                value.nil? ? default_value : value,
              }
            end
          end
        %}
      {% end %}
    end
  end
end
