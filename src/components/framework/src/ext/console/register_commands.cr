module Athena::Framework::CompilerPasses::RegisterCommands
  # Post arguments avoid dependency resolution
  include Athena::DependencyInjection::PostArgumentsCompilerPass

  macro included
    macro finished
      {% verbatim do %}
        {%
          command_map = {} of Nil => Nil
          command_refs = {} of Nil => Nil

          # Services that are not configured via the annotation so must be registered eagerly.
          eager_service_ids = [] of Nil

          (TAG_HASH["athena.console.command"] || [] of Nil).each do |service_id|
            metadata = SERVICE_HASH[service_id]

            # TODO: Any benefit in allowing commands to be configured via tags instead of the annotation?

            metadata[:visibility] = metadata[:visibility] != Visibility::PRIVATE ? metadata[:visibility] : Visibility::INTERNAL

            ann = metadata[:service].annotation ACONA::AsCommand

            if ann == nil
              if metadata[:visibility] == Visibility::PRIVATE
                SERVICE_HASH[public_service_id = "_#{service_id.id}_public"] = metadata + {visibility: Visibility::INTERNAL}
                service_id = public_service_id
              end
              eager_service_ids << service_id.id
            else
              name = ann[0] || ann[:name]

              unless name
                ann.raise "Console command '#{metadata[:service]}' has an 'ACONA::AsCommand' annotation but is missing the commands's name. It was not provided as the first positional argument nor via the 'name' field."
              end

              aliases = name.split '|'
              aliases = aliases + (ann[:aliases] || [] of Nil)

              if ann[:hidden] && "" != aliases[0]
                aliases.unshift ""
              end

              command_name = aliases[0]
              aliases = aliases[1..]

              if is_hidden = "" == command_name
                command_name = aliases[0]
                aliases = aliases[1..]
              end

              command_map[command_name] = metadata[:service]
              command_refs[metadata[:service]] = service_id

              aliases.each do |a|
                command_map[a] = metadata[:service]
              end

              SERVICE_HASH[lazy_service_id = "_#{service_id.id}_lazy"] = {
                visibility: Visibility::INTERNAL,
                service:    "ACON::Commands::Lazy",
                ivar_type:  "ACON::Commands::Lazy",
                tags:       [] of Nil,
                generics:   [] of Nil,
                arguments:  [
                  {value: command_name},
                  {value: "#{aliases} of String".id},
                  {value: ann[:description] || ""},
                  {value: is_hidden},
                  {value: "->{ #{service_id.id}.as(ACON::Command) }".id},
                ],
              }

              command_refs[metadata[:service]] = lazy_service_id
            end
          end

          SERVICE_HASH[loader_id = "athena_console_command_loader_container"] = {
            visibility: Visibility::INTERNAL,
            service:    "Athena::Framework::Console::ContainerCommandLoaderLocator",
            ivar_type:  "Athena::Framework::Console::ContainerCommandLoaderLocator",
            tags:       [] of Nil,
            generics:   [] of Nil,
            arguments:  [
              {value: "self".id},
            ],
          }

          SERVICE_HASH[command_loader_service_id = "athena_console_command_loader"] = {
            visibility: Visibility::PUBLIC,
            alias:      ACON::Loader::Interface,
            service:    Athena::Framework::Console::ContainerCommandLoader,
            ivar_type:  Athena::Framework::Console::ContainerCommandLoader,
            tags:       [] of Nil,
            generics:   [] of Nil,
            arguments:  [
              {value: "#{command_map} of String => ACON::Command.class".id},
              {value: loader_id.id},
            ],
          }

          SERVICE_HASH["athena_console_application"][:arguments][0][:value] = command_loader_service_id.id
          SERVICE_HASH["athena_console_application"][:arguments][2][:value] = "#{eager_service_ids} of ACON::Command".id
        %}

        # :nodoc:
        #
        # TODO: Define some more generic way to create these
        struct ::Athena::Framework::Console::ContainerCommandLoaderLocator
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
