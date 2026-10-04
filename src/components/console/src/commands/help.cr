# Displays information for a given command.
@[Athena::Console::Annotations::AsCommand("help", description: "Display help for a command")]
class Athena::Console::Commands::Help < Athena::Console::Command
  # :nodoc:
  setter command : ACON::Command? = nil

  protected def configure : Nil
    self.ignore_validation_errors

    self
      .name("help")
      .argument("command_name", description: "The command name", default: "help") { ACON::Descriptor::Application.new(self.application).commands.keys }
      .option("format", value_mode: :required, description: "The output format (txt)", default: "txt") { ACON::Helper::Descriptor.new.formats }
      .option("raw", value_mode: :none, description: "To output raw command help")
      .help(
        <<-HELP
        The <info>%command.name%</info> command displays help for a given command:

          <info>%command.full_name% list</info>

        To display the list of available commands, please use the <info>list</info> command.
        HELP
      )

    self.definition.ignore_extra_arguments = true
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    if @command.nil?
      application = self.application
      name = input.argument("command_name", String)

      if input.is_a? ACON::Input::ARGV
        # A spaced path names a command in a tree: `help docker compose`.
        input.unparsed_tokens.each do |token|
          child_path = "#{application.has?(name) ? application.get(name).name : name}:#{token}"
          break if !application.has?(child_path) && !self.namespace?(child_path)

          name = child_path
        end
      end

      @command = if !application.has?(name) && self.namespace?(name)
                   ACON::Commands::Group.new(name).tap(&.application=(application))
                 else
                   application.find name
                 end
    end

    ACON::Helper::Descriptor.new.describe(
      output,
      @command.not_nil!,
      ACON::Descriptor::Context.new(
        format: input.option("format", String),
        raw_text: input.option("raw", Bool),
      )
    )

    @command = nil

    ACON::Command::Status::SUCCESS
  end

  # Only resolves the commands below the provided *path*, unlike `ACON::Application#namespaces` which resolves them all.
  private def namespace?(path : String) : Bool
    self.application.commands(path).any? { |_, command| !command.hidden? }
  end
end
