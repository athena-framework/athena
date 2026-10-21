# Hashes a password with the `APH::Interface` an `APH::FactoryInterface` returns for a user class.
# Mainly used to generate passwords for in-memory users, or to change passwords in the database while developing an application.
#
# ```text
# $ ./bin/console security:hash-password
# $ ./bin/console security:hash-password '' 'App::User'
# $ echo $PASSWORD | ./bin/console security:hash-password --no-interaction -
# ```
#
# NOTE: Requires the [Console](/Console/) component, and is not registered as a service automatically.
@[ACONA::AsCommand("security:hash-password", description: "Hash a user password")]
class Athena::PasswordHasher::Commands::UserPasswordHash < ACON::Command
  def initialize(
    @hasher_factory : APH::FactoryInterface,
    @user_classes : Array(String) = [] of String,
  )
    super()
  end

  # :inherit:
  def complete(input : ACON::Completion::Input, suggestions : ACON::Completion::Suggestions) : Nil
    if input.must_suggest_argument_values_for? "user-class"
      suggestions.suggest_values @user_classes
    end
  end

  protected def configure : Nil
    self
      .argument("password", description: "The plain password to hash.")
      .argument("user-class", description: "The user class associated with the hasher used to hash the password.")
      .help(<<-HELP)
        The <info>%command.name%</info> command hashes passwords according to your
        password hasher configuration. This command is mainly used to generate passwords for
        in-memory users, and for changing passwords in the database while developing the application.

        Executing the command interactively prompts for the password and uses
        the first configured user class:

          <info>%command.full_name%</info>

        Pass the user class as the second argument to hash passwords for
        your own types (pass <comment>''</comment> as the first argument to keep the interactive prompt):

          <info>%command.full_name% '' 'App::User'</info>

        Passing the password on the command line is supported for non-interactive
        use, but exposes the plaintext to shell history and the process list.

        Read the password from standard input by passing <comment>-</comment> as the password
        argument; this avoids exposing it to shell history or the process list:

          <info>echo $PASSWORD | %command.full_name% --no-interaction -</info>
        HELP
  end

  # ameba:disable Metrics/CyclomaticComplexity
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    style = ACON::Style::Athena.new input, output
    error_style = output.is_a?(ACON::Output::ConsoleOutputInterface) ? ACON::Style::Athena.new(input, output.error_output) : style

    input.interactive? ? error_style.title("Athena Password Hash Utility") : error_style.new_line

    password = input.argument "password"

    if "-" == password
      stream = input.is_a?(ACON::Input::Streamable) ? input.stream : nil
      password = (stream || STDIN).gets(chomp: true) || ""
    elsif password.presence && input.interactive?
      error_style.warning %(Passing the password as a command argument exposes it to shell history and the process list (ps, /proc/<pid>/cmdline, container audit logs); prefer the interactive prompt or pass "-" to read it from stdin.)
    end

    hasher = @hasher_factory.password_hasher self.user_class(input, style)

    if password.nil? || password.empty?
      unless input.interactive?
        error_style.error "The password must not be empty."

        return ACON::Command::Status::FAILURE
      end

      password = error_style.ask(self.password_question).as(String)
    end

    style.table(
      {"Key", "Value"},
      [
        {"Hasher used", hasher.class.to_s},
        {"Password hash", hasher.hash(password)},
      ]
    )

    error_style.note "Self-salting hasher used: the hasher generated its own built-in salt."
    error_style.success "Password hashing succeeded"

    ACON::Command::Status::SUCCESS
  end

  private def password_question : ACON::Question(String?)
    question = ACON::Question(String?).new "Type in your password to be hashed", nil
    question.hidden = true
    question.max_attempts = 20
    question.validator do |value|
      raise ACON::Exception::InvalidArgument.new "The password must not be empty." if value.nil? || value.blank?

      value
    end

    question
  end

  private def user_class(input : ACON::Input::Interface, style : ACON::Style::Athena) : String
    if user_class = input.argument "user-class"
      return user_class
    end

    raise APH::Exception::Runtime.new "There are no configured password hashers." if @user_classes.empty?

    if !input.interactive? || 1 == @user_classes.size
      return @user_classes.first
    end

    user_classes = @user_classes.sort_by &.downcase

    style.choice("For which user class would you like to hash a password?", user_classes, user_classes.first).as(String)
  end
end
