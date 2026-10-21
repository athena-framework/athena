# Displays the configuration of the migrations, the current, previous, next and latest versions, and the number of executed, available and new migrations.
#
# ```text
# $ ./bin/console orm:migrations:status
# ```
@[ACONA::AsCommand("orm:migrations:status", description: "View the status of a set of migrations.")]
class Athena::ORM::Migrations::Commands::Status < Athena::ORM::Migrations::Commands::AbstractCommand
  def initialize(
    @migration_status_infos_helper : AORM::Migrations::Commands::MigrationStatusInfosHelper,
  )
    super()
  end

  protected def configure : Nil
    self
      .help(<<-HELP)
        The <info>%command.name%</info> command outputs the status of a set of migrations:

            <info>%command.full_name%</info>
        HELP
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    @migration_status_infos_helper.show_migrations_info output

    ACON::Command::Status::SUCCESS
  end
end
