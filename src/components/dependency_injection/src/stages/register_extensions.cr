require "compiler/crystal/macros"

# :nodoc:
module Athena::DependencyInjection::ServiceContainer::RegisterExtensions
  macro included
    macro finished
      {% verbatim do %}
        {%
          EXTENSIONS.each do |k, v|
            if config = CONFIG[k]
              pp config

              v.each do |config_key, config_value|
                config_value.each do |type|
                  pp type.type
                  if sc = config[config_key][type.var]
                    pp sc.receiver
                    resolved_type = parse_type("Crystal::Macros::#{sc.class_name.id}").resolve

                    pp sc.receiver.resolve <= type.type.resolve

                    raise "Incorrect type" unless resolved_type <= type.type.resolve
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
