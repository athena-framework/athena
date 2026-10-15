# Generates a blank migration in the configured directory and namespace.
#
# ```text
# $ ./bin/console orm:migrations:generate
# ```
#
# The application must be rebuilt before the migration can be executed.
@[ACONA::AsCommand("orm:migrations:generate", description: "Generate a blank migration class.")]
class Athena::ORM::Migrations::Commands::Generate < Athena::ORM::Migrations::Commands::AbstractCommand
  def initialize(
    @configuration : AORM::Migrations::Configuration,
    @generator : AORM::Migrations::Generator,
    @class_name_generator : AORM::Migrations::Generator::ClassNameGenerator,
  )
    super()
  end

  protected def configure : Nil
    self
      .help(<<-HELP)
        The <info>%command.name%</info> command generates a blank migration class:

            <info>%command.full_name%</info>
        HELP
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    fqcn = @class_name_generator.generate_class_name @configuration.namespace
    path = @generator.generate_migration fqcn

    self.io.text [
      %(Generated new migration class to "<info>#{path}</info>"),
      "",
      "Rebuild the application for the migration to be available.",
      "",
      %(To run just this migration for testing purposes, you can use <info>orm:migrations:execute --up '#{fqcn}'</info>),
      "",
      %(To revert the migration you can use <info>orm:migrations:execute --down '#{fqcn}'</info>),
      "",
    ]

    ACON::Command::Status::SUCCESS
  end
end
