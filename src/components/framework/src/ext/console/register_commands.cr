module Athena::Framework::CompilerPasses::RegisterCommands
  # Post arguments avoid dependency resolution
  include Athena::DependencyInjection::PostArgumentsCompilerPass

  private LOCATORS = [] of Nil

  macro included
    macro finished
      {% verbatim do %}
        {%
          command_map = {} of Nil => Nil
          command_refs = {} of Nil => Nil

          (TAG_HASH["athena.console.command"] || [] of Nil).each do |service_id|
            metadata = SERVICE_HASH[service_id]

            # TODO: Figure out way to make this not public
            metadata[:visibility] = metadata[:visibility] != Visibility::PRIVATE ? metadata[:visibility] : Visibility::INTERNAL

            tags = metadata[:tags].select &.[:name].==("athena.console.command")

            # If `command` is set on the first tag, use that as aliases
            # otherwise resolve from the `AsCommand` annotation

            if !tags.empty? && (ann = metadata[:service].annotation ACONA::AsCommand)
              aliases = if tag_command = tags[0][:command]
                          tag_command
                        else
                          ann[0] || ann[:name]
                        end

              aliases = (aliases || "").split "|"
              command_name = aliases[0]
              aliases = aliases[1..]

              if is_hidden = "" == command_name
                command_name = aliases[0]

                unless aliases.empty?
                  aliases = aliases[1..]
                end
              end

              if command_name == nil
                # TODO: Do something here?
                # Make public alias for the command?
              end

              description = tags[0][:description]

              tags = tags[1..]

              command_map[command_name] = metadata[:service]
              command_refs[metadata[:service]] = service_id

              aliases.each do |a|
                command_map[a] = metadata[:service]
              end

              if !description
                description = ann[:description]
              end

              # TODO: Add method calls to handle additional aliases, hidden commands, and description
            end
          end

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
                {value: command_map},
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
              def get(service : {{service_type}}.class) : {{service_type}}
                @container.{{service_id.id}}
              end
            {% end %}

            def get(service)
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
