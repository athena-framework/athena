# :nodoc:
#
# Merges successive calls to `ADI.configure`, with the last ones winning.
module Athena::DependencyInjection::ServiceContainer::MergeConfigs
  macro included
    macro finished
      {% verbatim do %}
        {%
          to_process = [] of Nil

          CONFIGS.each do |c|
            c.to_a.each do |tup|
              to_process << {tup[0], tup[1], c, [tup[0]], CONFIG}
            end
          end

          to_process.each do |(k, v, h, stack, root)|
            if v.is_a?(NamedTupleLiteral)
              v.to_a.each do |(sk, sv)|
                to_process << {sk, sv, v, stack + [sk], root}
              end
            else
              stack[..-2].each_with_index do |sk, idx|
                if root[sk] == nil
                  root[sk] = {__nil: nil} # Ensure this is a NamedTupleLiteral
                end

                root = root[sk]
              end

              root[k] = v
            end
          end
        %}
      {% end %}
    end
  end
end
