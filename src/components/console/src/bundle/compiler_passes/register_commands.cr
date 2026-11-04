# :nodoc:
#
# Registers the services tagged `console.command` with the `console_command_loader` service.
# Commands with an `ACONA::AsCommand` annotation are wrapped in an `ACON::Commands::Lazy` so they are only instantiated when executed.
module Athena::Console::Bundle::CompilerPasses::RegisterCommands
  macro included
    macro finished
      {% verbatim do %}
        {%
          # The ID of the lazy command service of each command name, including aliases.
          command_map = {} of Nil => Nil

          # The IDs of the services wrapping the commands configured via the annotation in an `ACON::Commands::Lazy`.
          lazy_service_ids = [] of Nil

          # Services that are not configured via the annotation so must be registered eagerly.
          eager_service_ids = [] of Nil

          (TAG_HASH["console.command"] || [] of Nil).each do |(service_id, _attributes)|
            metadata = SERVICE_HASH[service_id]

            # TODO: Any benefit in allowing commands to be configured via tags instead of the annotation?

            ann = metadata["class"].annotation ACONA::AsCommand

            if ann == nil
              SERVICE_HASH[public_service_id = "_#{service_id.id}_public"] = metadata
              service_id = public_service_id
              eager_service_ids << service_id.id
            else
              name = ann[0] || ann[:name]

              unless name
                ann.raise "Console command '#{metadata["class"]}' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field."
              end

              aliases = name.split '|'
              aliases = aliases + (ann["aliases"] || [] of Nil)

              if ann["hidden"] && "" != aliases[0]
                aliases.unshift ""
              end

              command_name = aliases[0]
              aliases = aliases[1..]

              if is_hidden = "" == command_name
                command_name = aliases[0]
                aliases = aliases[1..]
              end

              lazy_service_id = "_#{service_id.id}_lazy"

              command_map[command_name] = lazy_service_id

              aliases.each do |a|
                command_map[a] = lazy_service_id
              end

              SERVICE_HASH[lazy_service_id] = {
                class:               ACON::Commands::Lazy,
                tags:                [] of Nil,
                generics:            [] of Nil,
                calls:               [] of Nil,
                public:              false,
                referenced_services: [service_id],
                parameters:          {
                  name:        {value: command_name},
                  aliases:     {value: "#{aliases} of String".id},
                  description: {value: ann["description"] || ""},
                  hidden:      {value: is_hidden},
                  command:     {value: "->{ #{service_id.id}.as(ACON::Command) }".id},
                },
              }

              lazy_service_ids << lazy_service_id
            end
          end

          # Built here as this pass runs after the values of service locator parameters are resolved.
          lazy_command_factories = lazy_service_ids.map { |lazy_service_id| "#{lazy_service_id} => ->{ #{lazy_service_id.id}.as(ACON::Command) }" }

          SERVICE_HASH["console_command_loader"] = {
            class:    Athena::Console::Bundle::ContainerCommandLoader,
            tags:     [] of Nil,
            generics: [] of Nil,
            calls:    [] of Nil,
            public:   true,
            # Track the commands as referenced services to ensure their getters are generated
            referenced_services: eager_service_ids + lazy_service_ids,
            parameters:          {
              command_map:    {value: "#{command_map} of String => String".id},
              loader:         {value: "ADI::ServiceLocator(ACON::Command).new({#{lazy_command_factories.join(", ").id}} of String => Proc(ACON::Command))".id},
              eager_commands: {value: "#{eager_service_ids} of ACON::Command".id},
            },
          }
        %}
      {% end %}
    end
  end
end
