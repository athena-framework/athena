module Athena::Framework::CompilerPasses::RegisterCommands
  # Post arguments avoid dependency resolution
  include Athena::DependencyInjection::PostArgumentsCompilerPass

  private LOCATORS = [] of Nil

  macro included
    macro finished
      {% verbatim do %}
        {%
          service_ids = [] of Nil
          command_map = {} of Nil => Nil
          command_refs = {} of Nil => Nil

          (TAG_HASH["athena.console.command"] || [] of Nil).each do |service_id|
            metadata = SERVICE_HASH[service_id]

            # TODO: Any benefit in allowing commmands to be configured via tags instead of the annotation?

            metadata[:visibility] = metadata[:visibility] != Visibility::PRIVATE ? metadata[:visibility] : Visibility::INTERNAL

            if ann = metadata[:service].annotation ACONA::AsCommand
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

              if command_name == nil
                # TODO: Do something here?
                # Make public alias for the command?
              else
                description = ann[:description]

                command_map[command_name] = metadata[:service]
                command_refs[metadata[:service]] = service_id

                aliases.each do |a|
                  command_map[a] = metadata[:service]
                end

                if description
                  # TODO: Add method call to handle description
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
                    {value: description || ""},
                    {value: is_hidden},
                    {value: "->{ #{service_id.id}.as(ACON::Command) }".id},
                  ],
                }

                command_refs[metadata[:service]] = lazy_service_id

                # TODO: Add method calls to handle additional aliases, and hidden commands
              end
            end
          end

          # TODO: How to track eager commands?

          unless command_map.empty?
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

            SERVICE_HASH["athena_console_command_loader"] = {
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

            # FIXME: Is there a better way to handle this?
            SERVICE_HASH["athena_console_application"][:arguments][0][:value] = "athena_console_command_loader".id
          end
        %}

        {% unless command_refs.empty? %}
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
      {% end %}
    end
  end
end
