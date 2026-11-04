# :nodoc:
#
# Checks the custom authenticators of each firewall, and makes the one that is also an `ASEC::EntryPoint::Interface` its entry point if it has no `entry_point`.
# Runs after the services of the application are registered, as the authenticators typically are some of them.
module Athena::Security::Bundle::CompilerPasses::RegisterEntryPoints
  macro included
    macro finished
      {% verbatim do %}
        {%
          CONFIG["security"]["firewalls"].to_a.reject { |(name, _)| name.stringify == "__nil" }.each do |(name, firewall)|
            if firewall["security"]
              entry_point_ids = [] of Nil

              firewall["custom_authenticators"].each do |authenticator_id|
                unless definition = SERVICE_HASH[authenticator_id]
                  authenticator_id.raise "Invalid firewall '#{name.id}': the custom authenticator '#{authenticator_id.id}' is not a registered service."
                end

                unless definition["class"] <= Athena::Security::Authenticator::Interface
                  authenticator_id.raise "Invalid firewall '#{name.id}': the custom authenticator '#{authenticator_id.id}' (#{definition["class"]}) must include 'ASEC::Authenticator::Interface'."
                end

                entry_point_ids << authenticator_id if definition["class"] <= Athena::Security::EntryPoint::Interface
              end

              if entry_point_id = firewall["entry_point"]
                unless definition = SERVICE_HASH[entry_point_id]
                  entry_point_id.raise "Invalid firewall '#{name.id}': the entry point '#{entry_point_id.id}' is not a registered service."
                end

                unless definition["class"] <= Athena::Security::EntryPoint::Interface
                  entry_point_id.raise "Invalid firewall '#{name.id}': the entry point '#{entry_point_id.id}' (#{definition["class"]}) must include 'ASEC::EntryPoint::Interface'."
                end
              elsif entry_point_ids.size == 1
                SERVICE_HASH["athena_security_exception_listener_#{name}"]["parameters"]["authentication_entry_point"]["value"] = "@#{entry_point_ids[0].id}"
              elsif entry_point_ids.size > 1
                name.raise "Because you have multiple authenticators in firewall '#{name.id}', you need to set the 'entry_point' key to one of your authenticators ('#{entry_point_ids.join("', '").id}') or a service ID implementing 'ASEC::EntryPoint::Interface'. The 'entry_point' determines what should happen (e.g. redirect to '/login') when an anonymous user tries to access a protected page."
              end
            end
          end
        %}
      {% end %}
    end
  end
end
