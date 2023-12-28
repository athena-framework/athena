module Athena::Framework
  # :nodoc:
  abstract struct AbstractBundle
    PASSES = [] of Nil
  end

  macro register_bundle(bundle)
    {%
      resolved_bundle = bundle.resolve

      bundle.raise "Must be a child of 'ATH::AbstractBundle'." unless resolved_bundle <= AbstractBundle

      ann = resolved_bundle.annotation Athena::Framework::Annotations::Bundle

      bundle.raise "Unable to determine extension name." unless (name = ann[0] || ann["name"])
    %}

    ADI.register_extension {{name}}, {{"::#{bundle.id}::Schema".id}}

    {% for pass in resolved_bundle.constant("PASSES") %}
      ADI.add_compiler_pass {{pass.splat}}
    {% end %}
  end

  macro configure(config)
    ADI.configure({{config}})
  end
end
