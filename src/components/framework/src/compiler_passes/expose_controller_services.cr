module Athena::Framework::CompilerPasses::MakeControllerServicesPublicPass
  macro included
    macro finished
      {% verbatim do %}
        {%
          SERVICE_HASH.each do |service_id, metadata|
            if metadata["class"] <= ATH::Controller
              metadata["public"] = true
            end
          end
        %}
      {% end %}
    end
  end
end
