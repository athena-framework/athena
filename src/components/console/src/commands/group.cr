# A command that groups the sub-commands registered below its name, listing them when invoked without one.
#
# It can be used as is, or extended in order to define options that apply to the group itself.
# See [Sub-commands][Athena::Console::Command--sub-commands] for more information.
#
# ```
# @[ACONA::AsCommand("docker", description: "Manage containers")]
# class DockerCommand < ACON::Commands::Group
#   protected def configure : Nil
#     self
#       .option("context", "c", :required, "The context to use")
#   end
# end
#
# # Or without a dedicated type
# application.add ACON::Commands::Group.new("docker").option("context", "c", :required, "The context to use")
# ```
#
# Invoking the group directly, e.g. `./console docker`, writes the list of its sub-commands to the error output and returns `ACON::Command::Status::FAILURE`.
# The same happens when invoking a namespace without a registered command, such as `./console docker:compose`.
class Athena::Console::Commands::Group < Athena::Console::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    if (application = self.application?) && !application.commands(self.name).empty?
      # Buffered so that nothing is written if the namespace turns out to only contain hidden commands.
      buffer = ACON::Output::IO.new IO::Memory.new, output.verbosity, output.decorated?, output.formatter
      ACON::Helper::Descriptor.new.describe buffer, application, ACON::Descriptor::Context.new(namespace: self.name)

      (output.is_a?(ACON::Output::ConsoleOutputInterface) ? output.error_output : output).print buffer.to_s, output_type: :raw

      return ACON::Command::Status::FAILURE
    end

    raise ACON::Exception::Logic.new "The '#{self.name}' command group does not have any sub-commands."
  end
end
