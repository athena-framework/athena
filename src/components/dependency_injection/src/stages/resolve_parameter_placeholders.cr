# :nodoc:
module Athena::DependencyInjection::ServiceContainer::ResolveParameterPlaceholders
  macro included
    macro finished
      {% verbatim do %}

        # I hate how much code it takes to do this, but is quite cool I got it to work.
        # WTB https://github.com/crystal-lang/crystal/issues/8835 :((
        #
        # The purpose of this module is to resolve placeholder values within various parameters.
        # E.g. `"https://%app.domain%/"` => `"https://example.com/"`.
        #
        # It is assumed that any user added parameters via another module have already happened.
        # Parameters added after this module will not be resolved.
        #
        # The macro API is quite limited compared to the normal stdlib API.
        # As such we do not have access to recursion, nor do we have the ability to use a regex to extract the parameter name from the value.
        # These together makes this code quite crazy to grok.
        #
        # We first create an array that we can iterate over, using a somewhat custom variation of `NamedTupleLiteral#to_a` that also includes the collection the related key/value are located at.
        # The first tuple in this array is for the configuration parameters are these are most likely going to need to be resolved first anyway.
        # We then add the rest of the tuples, all using the `CONFIG` hash as the root collection.
        # Having this array is important since arrays are reference types, we can push more things to it while looping thru it to have somewhat pseudo recursion; this will be important later.
        # Next, we iterate over each key/value/collection grouping in the array, checking if the value is a supported type:
        #
        # * A string literal that has `%%` in it, or any text in between two `%`.
        # * A hash literal where one of the value of that hash has a `%%` in it, or any text in between two `%`.
        #   * NOTE: NamedTuple literals are _NOT_ supported as a terminal value, use a HashLiteral instead
        # * An array/tuple literal whose value has a `%%` in it, or any text in between two `%`.
        #
        # In each case, in order to extract the parameter name from the string, we iterate over the characters that make up the string, building out the key based on the chars between the `%`s.
        # This is done via the following algorithm:
        #
        # 1. If the current char is a `%` and next char is a `%` we skip as that implies the `%%` context which is an escaped `%`.
        # 2. If this is the first time we saw a `%` and the current char is a `%` and we're either at the beginning, or the previous char wasn't a `%`,
        #    then we know we're not starting to parse the parameter key.
        # 3. If we're in parameter key parsing mode and the current char is a `%` we know we're done and can resolve this key's placeholder
        #    by first looking up the parameter's value within `CONFIG["parameters"]`,
        #    ensuring its a string, resetting the key (since there may be multiple placeholders), finally exiting parameter key parsing mode.
        # 4. If we're in parameter key parsing mode, but the current character is not `%`, we append this character to the `key` variable
        # 5. If we're not in parameter key parsing mode, we append this character to the `new_value` variable, which represents the rebuilt value with placeholders resolved.
        #
        # After all this we'll either end up with a fully resolved value, denoted by it not longer matching the regex, or a value that needs additional placeholders resolved,
        # e.g. because the parameters it depends on are not yet resolved, or was resolved to a value that contained other yet to be resolved values.
        # In either case, if the value is not fully resolved we push the same key, but the new value _BACK_ into the original array we're iterating over along with the collection they belong to.
        # This will cause it to loop again and start the process all over on the previously resolved value;
        # this will run until either they're all resolved, or an unknown parameter is encountered.
        #
        # The process is also essentially the same for array/hash literals, but operating on the sub-hash's value or the array's elements.
        # But are two main differences:
        #
        # 1.The path to the value we're updating is no longer _just_ `CONFIG["parameters"][k]`, but the key/index of the collection.
        # 2. In the re-process context, we're pushing the whole collection, as the value, which should match the left hand side of the assignment above it, minus the sub-key/index.

        {%
          to_process = CONFIG.to_a.map { |tup| {tup[0], tup[1], CONFIG, [tup[0]]} }

          to_process.each do |(k, v, h, stack)|
            if v.is_a?(NamedTupleLiteral)
              v.to_a.each do |(sk, sv)|
                to_process << {sk, sv, v, stack + [sk]}
              end
            else
              if v.is_a?(StringLiteral) && v =~ /%%|%([^%\s]++)%/
                key = ""
                char_is_part_of_key = false

                new_value = ""

                chars = v.chars

                chars.each_with_index do |c, idx|
                  if c == '%' && chars[idx + 1] == '%'
                    # Do nothing as we'll just add the next char
                  elsif !char_is_part_of_key && c == '%' && (idx == 0 || chars[idx - 1] != '%')
                    char_is_part_of_key = true
                  elsif char_is_part_of_key && c == '%'
                    resolved_value = CONFIG["parameters"][key]

                    if resolved_value == nil
                      path = "#{stack[0]}"

                      stack[1..].each do |p|
                        path += "[#{p}]"
                      end

                      key.raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}' referenced unknown parameter '#{key.id}'."
                    end

                    if new_value.empty?
                      new_value = resolved_value
                    else
                      new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                    end

                    key = ""
                    char_is_part_of_key = false
                  elsif char_is_part_of_key
                    key += c
                  else
                    new_value += c
                  end
                end

                if !new_value.is_a?(StringLiteral) || (new_value.is_a?(StringLiteral) && !(new_value =~ /%%|%([^%\s]++)%/))
                  h[k] = new_value
                else
                  to_process << {k, new_value, h, stack}
                end
              elsif v.is_a?(HashLiteral)
                v.each do |sk, sv|
                  if sv.is_a?(StringLiteral) && sv =~ /%%|%([^%\s]++)%/
                    key = ""
                    char_is_part_of_key = false

                    new_value = ""

                    chars = sv.chars

                    chars.each_with_index do |c, c_idx|
                      if c == '%' && chars[c_idx + 1] == '%'
                        # Do nothing as we'll just add the next char
                      elsif !char_is_part_of_key && c == '%' && (c_idx == 0 || chars[c_idx - 1] != '%')
                        char_is_part_of_key = true
                      elsif char_is_part_of_key && c == '%'
                        resolved_value = CONFIG["parameters"][key]

                        if resolved_value == nil
                          path = "#{stack[0]}"

                          stack[1..].each do |p|
                            path += "[#{p}]"
                          end

                          h[k][sk].raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}[#{sk}]' referenced unknown parameter '#{key.id}'."
                        end

                        if new_value.empty?
                          new_value = resolved_value
                        else
                          new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                        end

                        key = ""
                        char_is_part_of_key = false
                      elsif char_is_part_of_key
                        key += c
                      else
                        new_value += c
                      end
                    end

                    if !new_value.is_a?(StringLiteral) || (new_value.is_a?(StringLiteral) && !(new_value =~ /%%|%([^%\s]++)%/))
                      h[k][sk] = new_value
                    else
                      to_process << {k, h[k], h, stack}
                    end
                  end
                end
              elsif v.is_a?(ArrayLiteral) || v.is_a?(TupleLiteral)
                v.each_with_index do |av, a_idx|
                  if av.is_a?(StringLiteral) && av =~ /%%|%([^%\s]++)%/
                    key = ""
                    char_is_part_of_key = false

                    new_value = ""

                    chars = av.chars

                    chars.each_with_index do |c, c_idx|
                      if c == '%' && chars[c_idx + 1] == '%'
                        # Do nothing as we'll just add the next char
                      elsif !char_is_part_of_key && c == '%' && (c_idx == 0 || chars[c_idx - 1] != '%')
                        char_is_part_of_key = true
                      elsif char_is_part_of_key && c == '%'
                        resolved_value = CONFIG["parameters"][key]

                        if resolved_value == nil
                          path = "#{stack[0]}"

                          stack[1..].each do |p|
                            path += "[#{p}]"
                          end

                          h[k][a_idx].raise "#{stack[0] == "parameters" ? "Parameter".id : "Configuration value".id} '#{path.id}[#{a_idx}]' referenced unknown parameter '#{key.id}'."
                        end

                        if new_value.empty?
                          new_value = resolved_value
                        else
                          new_value += resolved_value.is_a?(StringLiteral) ? resolved_value : resolved_value.stringify
                        end

                        key = ""
                        char_is_part_of_key = false
                      elsif char_is_part_of_key
                        key += c
                      else
                        new_value += c
                      end
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
