# Lists the available commands, optionally only including those in a specific namespace.
class Athena::Console::Commands::List < Athena::Console::Command
  protected def configure : Nil
    self
      .name("list")
      .description("List commands")
      .definition(
        ACON::Input::Argument.new("namespace", :optional, "Only list commands in this namespace"),
        ACON::Input::Option.new("raw", nil, :none, "To output raw command list"),
        ACON::Input::Option.new("format", nil, :required, "The output format (txt)", "txt"),
        ACON::Input::Option.new("short", nil, :none, "To skip describing command's arguments"),
      )
      .help(
        <<-HELP
        The <info>%command.name%</info> command lists all commands:

          <info>%command.full_name%</info>

        You can also display the commands for a specific namespace:

          <info>%command.full_name% test</info>

        It's also possible to get raw list of commands (useful for embedding command runner):

          <info>%command.full_name% --raw</info>
        HELP
      )
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    ACON::Helper::Descriptor.new.describe(
      output,
      self.application,
      ACON::Descriptor::Context.new(
        format: input.option("format", String),
        raw_text: input.option("raw", Bool),
        namespace: input.argument("namespace", String?),
        short: input.option("short", Bool)
      )
    )

    ACON::Command::Status::SUCCESS
  end
end
