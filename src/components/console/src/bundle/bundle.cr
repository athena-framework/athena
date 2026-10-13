# Integrates the Console component with the [dependency injection](/DependencyInjection/) component, such as within an [Athena Framework](/Framework/) application.
#
# Require `athena-console/bundle` to register the bundle; it does not require any configuration:
#
# ```
# require "athena-dependency_injection"
# require "athena-console/bundle"
# ```
#
# Commands registered as services are then added to an application created from the container, see `ACON::Application.new(name, version, container)`.
# Commands with an `ACONA::AsCommand` annotation are lazy, meaning they are only instantiated when they are executed:
#
# ```
# @[ADI::Register]
# @[ACONA::AsCommand("app:create-user", description: "Creates a user")]
# class CreateUserCommand < ACON::Command
#   def initialize(@user_repository : UserRepository)
#     super()
#   end
#
#   protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#     # ...
#
#     Status::SUCCESS
#   end
# end
#
# ACON::Application.new("My App", "1.0.0", ADI.container).run
# ```
#
# Within an Athena Framework application, use [ATH.run_console](/Framework/#Athena::Framework.run_console) instead.
@[ADI::Bundle("console")]
struct Athena::Console::Bundle < ADI::AbstractBundle
  # :nodoc:
  PASSES = [
    {Athena::Console::Bundle::CompilerPasses::RegisterCommands, :before_removing, nil},
  ]

  # :nodoc:
  module Schema
    include ADI::Extension::Schema
  end

  # :nodoc:
  module Extension
    macro included
      macro finished
        {% verbatim do %}
          {%
            AUTO_CONFIGURATIONS[Athena::Console::Command] = {
              tags: ["console.command"],
            }
          %}
        {% end %}
      end
    end
  end
end
