# :nodoc:
#
# Defaults the cookie name of the Mercure protocol 1.0 hubs without a configured `cookie_name` to `mercure_access_token` if the `framework.debug` parameter is `true`, as browsers drop `__Secure-` cookies over plain HTTP.
# Runs after the bundle extensions, as the framework's extension determines the parameter's default value.
module Athena::Mercure::Bundle::CompilerPasses::ConfigureDebugCookieName
  macro included
    macro finished
      {% verbatim do %}
        {%
          if true == CONFIG["parameters"]["framework.debug"]
            CONFIG["mercure"]["hubs"].to_a.reject { |(name, _)| name.stringify == "__nil" }.each do |(name, hub)|
              parameters = SERVICE_HASH["mercure_hub_#{name}"]["parameters"]

              if "1.0" == hub["protocol_version"] && nil == hub["cookie_name"]
                parameters["cookie_name"] = {value: "mercure_access_token"}
              end
            end
          end
        %}
      {% end %}
    end
  end
end
