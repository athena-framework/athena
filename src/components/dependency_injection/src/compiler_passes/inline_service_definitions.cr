# :nodoc:
#
# Marks private single-use services for inlining into their consumers.
# Precomputes inline setup code and variable names which DefineGetters uses.
# Supports nested inlining where service A depends on service B, both single-use.
module Athena::DependencyInjection::ServiceContainer::InlineServiceDefinitions
  macro included
    macro finished
      {% verbatim do %}
        {%
          __nil = nil

          # Build set of services that are targets of public aliases
          # Only type-only aliases (name is nil) can be public
          alias_targets = {} of Nil => Nil
          ALIASES.each do |alias_name, alias_entries|
            type_only_alias = alias_entries.find(&.["name"].nil?)
            if type_only_alias && type_only_alias["public"] == true
              alias_targets[type_only_alias["id"].id.stringify] = true
            end
          end

          # Build set of services that are referenced via Proxy (need getters for proc references)
          proxy_targets = {} of Nil => Nil
          SERVICE_HASH.each do |_, definition|
            if definition != nil && definition["referenced_services"]
              definition["referenced_services"].each do |ref_id|
                proxy_targets[ref_id.id.stringify] = true
              end
            end
          end

          # First pass: mark ALL single-use private services for inlining
          SERVICE_REFERENCES.each do |service_id, ref_info|
            definition = SERVICE_HASH[service_id]

            # Only inline if: not nil, not public, exactly one reference, not a public alias target, AND not a proxy target
            sid_str = service_id.id.stringify
            if definition != nil && ref_info["public"] == false && ref_info["count"] == 1 && !alias_targets[sid_str] && !proxy_targets[sid_str]
              definition["inlined"] = true
              # Pre-compute the variable name (service_id with dashes replaced)
              definition["inline_var"] = service_id.gsub(/-/, "_")
            end
          end

          # Second pass: compute inline setup code in dependency order
          # Uses a queue pattern - services whose deps aren't ready get pushed back for later processing
          to_process = [] of Nil
          SERVICE_HASH.each do |service_id, definition|
            if definition != nil && definition["inlined"]
              to_process << service_id
            end
          end

          to_process.each do |service_id|
            definition = SERVICE_HASH[service_id]

            if !definition["inline_setup"]
              # Check if all inlined dependencies have their setup computed
              can_compute = true
              if params = definition["parameters"]
                params.each do |_, param|
                  value = param["value"]

                  # Check direct service reference
                  value_str = value.id.stringify
                  dep = SERVICE_HASH[value_str]
                  if dep && dep["inlined"] && !dep["inline_setup"]
                    can_compute = false
                  end

                  # Check array elements
                  if value.is_a?(ArrayLiteral)
                    value.each do |v|
                      v_str = v.id.stringify
                      v_dep = SERVICE_HASH[v_str]
                      if v_dep && v_dep["inlined"] && !v_dep["inline_setup"]
                        can_compute = false
                      end
                    end
                  end
                end
              end

              # Check call arguments for inlined dependencies
              if calls = definition["calls"]
                calls.each do |call|
                  method, args = call
                  if args
                    args.each do |arg|
                      arg_dep = SERVICE_HASH[arg.stringify]
                      if arg_dep && arg_dep["inlined"] && !arg_dep["inline_setup"]
                        can_compute = false
                      end
                    end
                  end
                end
              end

              if can_compute
                service_name = definition["class"].is_a?(StringLiteral) ? definition["class"].id : definition["class"].name(generic_args: false)
                generics_type = "#{service_name}(#{definition["generics"].splat})".id
                service = definition["generics"].empty? ? definition["class"].id : generics_type.id

                constructor_service = service
                constructor_method = "new"

                if factory = definition["factory"]
                  constructor_service, constructor_method = factory
                end

                var_name = definition["inline_var"]
                setup_lines = [] of Nil

                # First, include setup code from all inlined dependencies in parameters
                if params = definition["parameters"]
                  params.each do |_, param|
                    value = param["value"]

                    # Check direct service reference
                    value_str = value.id.stringify
                    dep = SERVICE_HASH[value_str]
                    if dep && dep["inlined"] && dep["inline_setup"]
                      setup_lines << dep["inline_setup"]
                    end

                    # Check array elements
                    if value.is_a?(ArrayLiteral)
                      value.each do |v|
                        v_str = v.id.stringify
                        v_dep = SERVICE_HASH[v_str]
                        if v_dep && v_dep["inlined"] && v_dep["inline_setup"]
                          setup_lines << v_dep["inline_setup"]
                        end
                      end
                    end
                  end
                end

                # Include setup code from inlined dependencies in call arguments
                if calls = definition["calls"]
                  calls.each do |call|
                    method, args = call
                    if args
                      args.each do |arg|
                        arg_dep = SERVICE_HASH[arg.stringify]
                        if arg_dep && arg_dep["inlined"] && arg_dep["inline_setup"]
                          setup_lines << arg_dep["inline_setup"]
                        end
                      end
                    end
                  end
                end

                # Build parameter list, using inline_var for inlined deps
                param_strs = [] of Nil
                if params = definition["parameters"]
                  params.each do |name, param|
                    value = param["value"]
                    value_str = value.id.stringify
                    dep = SERVICE_HASH[value_str]

                    if dep && dep["inlined"] && dep["inline_var"]
                      param_strs << "#{name.id}: #{dep["inline_var"].id}"
                    elsif value.is_a?(ArrayLiteral)
                      # Handle array with potential inlined services
                      elements = value.map do |v|
                        v_str = v.id.stringify
                        v_dep = SERVICE_HASH[v_str]
                        if v_dep && v_dep["inlined"] && v_dep["inline_var"]
                          v_dep["inline_var"].id
                        else
                          v
                        end
                      end
                      str = "#{name.id}: [#{elements.splat}]"
                      # Always add type annotation for arrays (needed for empty arrays)
                      if (resolved_restriction = param["resolved_restriction"]) && resolved_restriction <= Array
                        str += " of Union(#{resolved_restriction.type_vars.splat})"
                      end
                      param_strs << str
                    else
                      param_strs << "#{name.id}: #{value}"
                    end
                  end
                end

                # Add this service's instantiation
                setup_lines << "#{var_name.id} = #{constructor_service}.#{constructor_method.id}(#{param_strs.join(", ").id})"

                # Add any calls on this service, transforming inlined service args
                if calls = definition["calls"]
                  calls.each do |call|
                    method, args = call
                    transformed_args = args.map do |arg|
                      arg_dep = SERVICE_HASH[arg.stringify]
                      if arg_dep && arg_dep["inlined"] && arg_dep["inline_var"]
                        arg_dep["inline_var"].id
                      else
                        arg
                      end
                    end
                    setup_lines << "#{var_name.id}.#{method.id}(#{transformed_args.splat})"
                  end
                end

                definition["inline_setup"] = setup_lines.join("\n")
              else
                # Dependencies not ready yet, push back for later processing
                to_process << service_id
              end
            end
          end
        %}
      {% end %}
    end
  end
end
