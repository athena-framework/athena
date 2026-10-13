# :nodoc:
#
# Registers the services tagged `console.command` with the `console_command_loader` service.
# Commands with an `ACONA::AsCommand` annotation are wrapped in an `ACON::Commands::Lazy` so they are only instantiated when executed.
module Athena::Console::Bundle::CompilerPasses::RegisterCommands
  macro included
    macro finished
      {% verbatim do %}
        {%
          command_map = {} of Nil => Nil
          command_refs = {} of Nil => Nil

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

              command_map[command_name] = metadata["class"]
              command_refs[metadata["class"]] = service_id

              aliases.each do |a|
                command_map[a] = metadata["class"]
              end

              SERVICE_HASH[lazy_service_id = "_#{service_id.id}_lazy"] = {
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

              command_refs[metadata["class"]] = lazy_service_id
            end
          end

          SERVICE_HASH[locator_id = "console_command_loader_locator"] = {
            class:               "Athena::Console::Bundle::ContainerCommandLoaderLocator",
            tags:                [] of Nil,
            generics:            [] of Nil,
            calls:               [] of Nil,
            public:              false,
            referenced_services: command_refs.values,
            parameters:          {
              container: {value: "self".id},
            },
          }

          SERVICE_HASH["console_command_loader"] = {
            class:    Athena::Console::Bundle::ContainerCommandLoader,
            tags:     [] of Nil,
            generics: [] of Nil,
            calls:    [] of Nil,
            public:   true,
            # Track eager commands as referenced services to ensure their getters are generated
            referenced_services: eager_service_ids,
            parameters:          {
              command_map:    {value: "#{command_map} of String => ACON::Command.class".id},
              loader:         {value: locator_id.id},
              eager_commands: {value: "#{eager_service_ids} of ACON::Command".id},
            },
          }
        %}

        # :nodoc:
        #
        # TODO: Define some more generic way to create these
        struct ::Athena::Console::Bundle::ContainerCommandLoaderLocator
          def initialize(@container : ::ADI::ServiceContainer); end

          {% for service_type, service_id in command_refs %}
            def get(service : {{service_type}}.class) : ACON::Command
              @container.{{service_id.id}}
            end
          {% end %}

          def get(service) : ACON::Command
            {% begin %}
              case service
              {% for service_type, service_id in command_refs %}
                when {{service_type}} then @container.{{service_id.id}}
              {% end %}
              else
                raise "BUG: Couldn't find correct service."
              end
            {% end %}
          end
        end
      {% end %}
    end
  end
end
