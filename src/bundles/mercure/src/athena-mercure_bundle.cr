require "athena-dependency_injection"
require "athena-event_dispatcher"
require "athena-http"
require "athena-mercure"

@[ADI::Register]
class Athena::MercureBundle::Discovery < AMC::Discovery
  def add_link(request : AHTTP::Request, hub_name : String? = nil) : Nil
    return if self.preflight_request? request.request

    hub = @hub_registry.hub hub_name

    # TODO: Create WebLink component?
    request.attributes.set("_links", [self.generate_link(hub.public_url)], Array(String))
  end
end

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
          # Built-in parameters
          {%
            cfg = CONFIG["mercure"]
            parameters = CONFIG["parameters"]

            pp cfg, parameters
          %}
        {% end %}
      end
    end
  end
end

ADI.register_bundle Athena::MercureBundle

ADI.configure({
  mercure: {
    foo: 123,
  },
})
