The Athena Framework comes with a built-in integration with the [Athena::Console][] component.
This integration can be a way to define alternate entry points into your business logic,
such as for use with scheduled jobs (Cron, Airflow, etc), or one-off internal/administrative things (running migrations, creating users, etc)
all the while sharing the same dependencies due to it also leveraging [dependency injection](../why_athena.md#dependency-injection).

## Basic Usage

Similar to [event listeners](./event_dispatcher.md), console commands can simply be registered as a service to be automatically registered.
If using the preferred [ACONA::AsCommand][] annotation, they are registered in a lazy fashion, meaning only the command(s) you execute will actually be instantiated.

```crystal
@[ADI::Register]
@[ACONA::AsCommand("admin:create-user", description: "Creates a new internal user")]
class AdminCreateUser < ACON::Command
  # A constructor can be defined to leverage existing services if applicable
  #def initialize(
  #  @some_serive : MyService
  #)
  #  # Just be sure to call `super()`!
  #  super()
  #end

  # Configure the command by adding arguments, options, aliases, etc.
  protected def configure : Nil
    self
      .argument("id", :required, "The employee's ID")
      .argument("name", :required, "The user's name")
      .argument("email", :optional, "The user's email. Assumed to be first.last if not provided")
      .option("admin", nil, :none, "If the user should be created as an internal admin")
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    # Provides a standardized format for how to display text in the terminal
    style = ACON::Style::Athena.new input, output

    input.argument "id", Int32   # => 12
    name = input.argument "name" # => "George Dietrich"
    input.argument "email"       # => nil
    input.option "admin", Bool   # => true

    # Implement your business logic

    style.success "Successfully created a user for #{name}!"

    # Note the command executed successfully
    Status::SUCCESS
  end
end
```

From here, if the application was created using the [skeleton](https://github.com/athena-framework/skeleton), commands can be executed via `shards run console -- admin:create-user 12 "George Dietrich" --admin`.
Otherwise see [Athena::Console][] for how to setup your CLI entry point.

NOTE: During development the console needs to re-build the application in order to have access to the changes made since last execution.
When deploying a production *console* binary, or if not doing any new console command dev, build it with the `--release` flag for increased performance locally.

## Built-in Commands

The framework also comes with some helpful built-in commands to either help with debugging, or provide framework specific features.
See each command within the [ATH::Commands][] namespace for more information.
