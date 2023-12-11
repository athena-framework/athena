# :nodoc:
#
# Merges successive calls to `ADI.configure`, with the last ones winning.
module Athena::DependencyInjection::ServiceContainer::MergeConfigs
  macro included
    macro finished
      {% verbatim do %}
        {%
          to_process = [] of Nil

          cfg = {parameters: {} of Nil => Nil} # Ensure this type is a NamedTupleLiteral

          CONFIGS.each do |cfg|
            cfg.to_a.each do |tup|
              to_process << {tup[0], tup[1], cfg, [tup[0]], cfg}
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
                  root[sk] = {} of Nil => Nil
                end

                root = root[sk]
              end

              root[k] = v
            end
          end

          cfg.each do |ck, cv|
            ADI::CONFIG[ck] = cv
          end
        %}
      {% end %}
    end
  end
end
