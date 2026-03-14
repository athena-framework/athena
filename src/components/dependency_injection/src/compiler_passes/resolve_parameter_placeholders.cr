# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ResolveParameterPlaceholders
  macro included
    macro finished
      {% verbatim do %}

        # Resolves `%parameter%` placeholders within configuration values.
        # E.g. `"https://%app.domain%/"` => `"https://example.com/"`.
        #
        # It is assumed that any user added parameters via another module have already happened.
        # Parameters added after this module will not be resolved.
        #
        # ## Processing strategy
        #
        # `to_process` is an array of `{key, value, collection, stack}` tuples. Since arrays are reference types,
        # we can push new items while iterating to achieve pseudo-recursion without actual recursion (which macros don't support).
        #
        # Each tuple tracks:
        # - `key`: the key within the collection to update
        # - `value`: the current value to inspect/resolve
        # - `collection`: the parent collection (CONFIG, a sub-hash, etc.) so we can write back resolved values
        # - `stack`: path segments for error messages (e.g., `["parameters", "app.name"]`)
        #
        # ## Supported value types
        #
        # * `StringLiteral` containing `%%` (escaped `%`) or `%param.name%` placeholders
        # * `HashLiteral` — each value is checked for placeholders
        #   * NOTE: NamedTuple literals are _NOT_ supported as a terminal value, use a HashLiteral instead
        # * `ArrayLiteral`/`TupleLiteral` — each element is checked for placeholders
        # * `NamedTupleLiteral` — recursively expanded into `to_process` for its children
        #
        # ## Placeholder resolution
        #
        # `StringLiteral#gsub` with a block replaces each `%param%` with its resolved value and `%%` with a literal `%`.
        #
        # When the entire string is a single placeholder (e.g., `"%app.debug%"`), the resolved value is looked up
        # directly from CONFIG rather than using the gsub result. This is critical for two reasons:
        # 1. It preserves non-string types (a `BoolLiteral` stays a `BoolLiteral`, not `"false"`)
        # 2. It preserves reference semantics for collections — if `%app.array%` resolves to an `ArrayLiteral`
        #    whose elements haven't been resolved yet, keeping the reference means those elements will be
        #    updated in-place when they're resolved later in the loop.
        #
        # If a resolved value still contains placeholders (e.g., because it references another parameter that
        # hasn't been resolved yet), it is pushed back into `to_process` for another pass.
        #
        # For hash/array values, the re-process entry pushes the whole sub-collection (`h[k]`) as the value,
        # which matches the assignment path (`h[k][sk]` / `h[k][a_idx]`) minus the sub-key/index.

        {%
          to_process = CONFIG.to_a.map { |tup| {tup[0], tup[1], CONFIG, [tup[0]]} }

          to_process.each do |(k, v, h, stack)|
            if v.is_a?(NamedTupleLiteral)
              v.to_a.each do |(sk, sv)|
                to_process << {sk, sv, v, stack + [sk]}
              end
            else
              if v.is_a?(StringLiteral) && v =~ /%%|%([^%\s]++)%/
                # gsub replaces each %param% with its resolved value, and %% with a literal %.
                # matches[1] is the captured parameter name, or nil for %% matches.
                new_value = v.gsub /%%|%([^%\s]++)%/ do |str, matches|
                  if param_name = matches[1]
                    resolved_value = CONFIG["parameters"][param_name]
                    if resolved_value == nil
                      path = "#{stack[0]}"

                      stack[1..].each do |p|
                        path += "[#{p}]"
                      end

                      param_name.raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}' referenced unknown parameter '#{param_name.id}'."
                    end

                    # gsub always returns a StringLiteral, so non-string values must be stringified here.
                    # The actual type is preserved below for single-placeholder values.
                    resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                  else
                    '%'
                  end
                end

                # When the entire value is a single placeholder (e.g., "%app.debug%"), replace the gsub
                # result with a direct lookup. This preserves non-string types (BoolLiteral, NumberLiteral,
                # etc.) and, critically, reference semantics for collections — an ArrayLiteral whose elements
                # haven't been resolved yet will be updated in-place when the loop processes them later.
                if v =~ /^%([^%\s]++)%$/
                  new_value = CONFIG["parameters"][v.gsub(/%/, "")]
                end

                # If fully resolved, assign it. Otherwise push back for another pass.
                if !new_value.is_a?(StringLiteral) || (new_value.is_a?(StringLiteral) && !(new_value =~ /%%|%([^%\s]++)%/))
                  h[k] = new_value
                else
                  to_process << {k, new_value, h, stack}
                end
              elsif v.is_a?(HashLiteral)
                # Same placeholder resolution as above, applied to each hash value.
                v.each do |sk, sv|
                  if sv.is_a?(StringLiteral) && sv =~ /%%|%([^%\s]++)%/
                    new_value = sv.gsub /%%|%([^%\s]++)%/ do |str, matches|
                      if param_name = matches[1]
                        resolved_value = CONFIG["parameters"][param_name]
                        if resolved_value == nil
                          path = "#{stack[0]}"

                          stack[1..].each do |p|
                            path += "[#{p}]"
                          end

                          param_name.raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}[#{sk}]' referenced unknown parameter '#{param_name.id}'."
                        end

                        resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                      else
                        '%'
                      end
                    end

                    # See single-placeholder comment above — same type/reference preservation applies.
                    if sv =~ /^%([^%\s]++)%$/
                      new_value = CONFIG["parameters"][sv.gsub(/%/, "")]
                    end

                    if !new_value.is_a?(StringLiteral) || (new_value.is_a?(StringLiteral) && !(new_value =~ /%%|%([^%\s]++)%/))
                      h[k][sk] = new_value
                    else
                      # Re-process the whole hash, not just the single value, since h[k][sk] is the assignment path.
                      to_process << {k, h[k], h, stack}
                    end
                  end
                end
              elsif v.is_a?(ArrayLiteral) || v.is_a?(TupleLiteral)
                # Same placeholder resolution as above, applied to each array/tuple element.
                v.each_with_index do |av, a_idx|
                  if av.is_a?(StringLiteral) && av =~ /%%|%([^%\s]++)%/
                    new_value = av.gsub /%%|%([^%\s]++)%/ do |str, matches|
                      if param_name = matches[1]
                        resolved_value = CONFIG["parameters"][param_name]
                        if resolved_value == nil
                          path = "#{stack[0]}"

                          stack[1..].each do |p|
                            path += "[#{p}]"
                          end

                          param_name.raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}[#{a_idx}]' referenced unknown parameter '#{param_name.id}'."
                        end

                        resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                      else
                        '%'
                      end
                    end

                    # See single-placeholder comment above — same type/reference preservation applies.
                    if av =~ /^%([^%\s]++)%$/
                      new_value = CONFIG["parameters"][av.gsub(/%/, "")]
                    end

                    if !new_value.is_a?(StringLiteral) || (new_value.is_a?(StringLiteral) && !(new_value =~ /%%|%([^%\s]++)%/))
                      h[k][a_idx] = new_value
                    else
                      to_process << {k, h[k], h, [] of Nil}
                    end
                  end
                end
              end
            end
          end
        %}
      {% end %}
    end
  end
end
