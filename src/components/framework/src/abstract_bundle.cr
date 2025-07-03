module Athena::Framework
  # :nodoc:
  abstract struct AbstractBundle
    PASSES = [] of Nil
  end

  # Registers the provided *bundle* with the framework.
  #
  # See the [Getting Started](/getting_started/configuration) docs for more information.
  macro register_bundle(bundle)
    {%
      resolved_bundle = bundle.resolve

      unless resolved_bundle <= AbstractBundle
        bundle.raise "The provided bundle '#{bundle}' be inherit from 'ATH::AbstractBundle'."
      end

      ann = resolved_bundle.annotation Athena::Framework::Annotations::Bundle

      unless name = ann[0] || ann["name"]
        bundle.raise "Unable to determine extension name. It was not provided as the first positional argument nor via the 'name' field."
      end
    %}

    ADI.register_extension {{name}}, {{"#{bundle.resolve.id}::Schema".id}}
    ADI.add_compiler_pass {{"#{bundle.resolve.id}::Extension".id}}, :before_optimization, 1028

    {% for pass in resolved_bundle.constant("PASSES") %}
      ADI.add_compiler_pass {{pass.splat}}
    {% end %}
  end

  # Primary entrypoint for configuring Athena Framework applications.
  #
  # See the [Getting Started](/getting_started/configuration) docs for more information.
  #
  # NOTE: This is an alias of [ADI.configure](/DependencyInjection/top_level/#Athena::DependencyInjection:configure(config)).
  macro configure(config)
    ADI.configure({{config}})
  end
end
