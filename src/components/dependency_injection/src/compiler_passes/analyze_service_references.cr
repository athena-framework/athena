# :nodoc:
#
# Builds a reference graph tracking which services are used and how many times.
# Populates SERVICE_REFERENCES with reference counts for use by optimization passes.
module Athena::DependencyInjection::ServiceContainer::AnalyzeServiceReferences
  macro included
    macro finished
      {% verbatim do %}
        {%
          __nil = nil

          # Initialize reference counts for all services
          SERVICE_HASH.each do |service_id, definition|
            if definition != nil
              SERVICE_REFERENCES[service_id] = {
                count:         0,
                public:        definition["public"] == true,
                referenced_by: [] of Nil,
              }
            end
          end

          # Analyze references
          SERVICE_HASH.each do |service_id, definition|
            if definition != nil
              # 1. Check parameter values for service references
              if parameters = definition["parameters"]
                parameters.each do |_, param|
                  value = param["value"]

                  # Direct service reference (bare identifier after ResolveValues)
                  if value && SERVICE_HASH[value.stringify] != nil
                    ref_id = value.stringify
                    SERVICE_REFERENCES[ref_id]["count"] += 1
                    SERVICE_REFERENCES[ref_id]["referenced_by"] << service_id
                  end

                  # Array of service references
                  if value.is_a?(ArrayLiteral)
                    value.each do |v|
                      if SERVICE_HASH[v.stringify] != nil
                        ref_id = v.stringify
                        SERVICE_REFERENCES[ref_id]["count"] += 1
                        SERVICE_REFERENCES[ref_id]["referenced_by"] << service_id
                      end
                    end
                  end
                end
              end

              # 2. Check calls array for service references
              if calls = definition["calls"]
                calls.each do |call|
                  method, args = call
                  if args
                    args.each do |arg|
                      if SERVICE_HASH[arg.stringify] != nil
                        ref_id = arg.stringify
                        SERVICE_REFERENCES[ref_id]["count"] += 1
                        SERVICE_REFERENCES[ref_id]["referenced_by"] << service_id
                      end
                    end
                  end
                end
              end

              # 3. Check explicit referenced_services metadata
              if referenced_services = definition["referenced_services"]
                referenced_services.each do |ref_id|
                  ref_id_str = ref_id.id.stringify
                  if SERVICE_HASH[ref_id_str] != nil
                    SERVICE_REFERENCES[ref_id_str]["count"] += 1
                    SERVICE_REFERENCES[ref_id_str]["referenced_by"] << service_id
                  end
                end
              end
            end
          end

          # 4. Count public aliases as references to their target services
          # Only type-only aliases (name is nil) can be public
          ALIASES.each do |alias_name, alias_entries|
            type_only_alias = alias_entries.find(&.["name"].nil?)
            if type_only_alias && type_only_alias["public"] == true
              target_id = type_only_alias["id"].id.stringify
              SERVICE_REFERENCES.keys.each do |key|
                if key.id.stringify == target_id
                  old_info = SERVICE_REFERENCES[key]
                  SERVICE_REFERENCES[key] = {
                    count:         old_info["count"] + 1,
                    public:        old_info["public"],
                    referenced_by: old_info["referenced_by"] << "alias:#{alias_name.id}",
                  }
                end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
