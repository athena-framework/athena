require "athena-dependency_injection"

@[ADI::Bundle("mercure")]
struct Athena::MercureBundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [] of _

  module Schema
    include ADI::Extension::Schema
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          {%

          %}
        {% end %}
      end
    end
  end
end

ADI.register_bundle Athena::MercureBundle
