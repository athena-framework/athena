# The parent type of the migrations commands.
#
# Messages logged to `AORM::Migrations::Log` while a command runs are written to its output instead of the log's backend: notices and above by default, info with `-v`, and debug, such as each executed query, with `-vv`.
abstract class Athena::ORM::Migrations::Commands::AbstractCommand < ACON::Command
  @io : ACON::Style::Athena? = nil

  # :inherit:
  #
  # Replaces the backend of `AORM::Migrations::Log` while running, so its entries are only written to the output.
  def run(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    log = AORM::Migrations::Log
    previous_backend = log.backend
    previous_level = log.initial_level

    # The backend filters entries by the output's verbosity itself.
    # The initial level is changed instead of the level, which can't be unset again once changed.
    log.backend = AORM::Migrations::Commands::ConsoleLogBackend.new output
    log.initial_level = :trace

    begin
      super
    ensure
      log.backend = previous_backend
      log.initial_level = previous_level
    end
  end

  protected def setup(input : ACON::Input::Interface, output : ACON::Output::Interface) : Nil
    @io = ACON::Style::Athena.new input, output
  end

  protected def io : ACON::Style::Athena
    @io.not_nil!
  end

  # Returns `true` if the command isn't interactive, or the user confirms *question*.
  protected def can_execute?(question : String, input : ACON::Input::Interface) : Bool
    !input.interactive? || self.io.confirm(question)
  end
end
