The `Athena::Console` component allows creating CLI based commands.
This integration can be a way to define alternate entry points into your business logic,
such as for use with scheduled jobs (Cron, Airflow, etc), or one-off internal/administrative things (running migrations, creating users, etc).

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-console:
    github: athena-framework/console
    version: ~> 0.4.0
```

## Usage

In its most basic form, a [ACON::Command][] consists of an `#execute` method that provides access to [input][ACON::Input::Interface] and [output][ACON::Output::Interface] of the command and returns a [ACON::Command::Status][] member.

```crystal
@[ACONA::AsCommand("app:create-user", description: "Manually create a user with the provided username")]
class CreateUserCommand < ACON::Command
  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : Status
    # Implement all the business logic here.

    # Indicates the command executed successfully.
    Status::SUCCESS
  end
end
```

However, in most cases the command will need to be configured to better fit its use case.
Commands may also implement a [#configure](/Console/Command/#Athena::Console::Command--configuring-the-command) method to accomplish this.
This method is where the [ACON::Input::Argument][]s and [ACON::Input::Option][]s may be defined, but also additional help output, aliases, etc.

```crystal
protected def configure : Nil
  self
    .argument("username", :required, "The username of the user")
    .aliases("new-user")
end
```

### Application

The core of the console component is the [ACON::Application][] type which is where all the registered [ACON::Command][]s are stored
as well as what controls what built-in command(s), global input options (flags), and [ACON::Helper][]s are available.
In most cases it provides a good starting point, but may be extended/customized if needed.

```crystal
# Create an ACON::Application, passing it the name of your CLI.
# Optionally accepts a second argument representing the version of the application.
application = ACON::Application.new "My CLI"

# Register commands using the `#add` method
application.add CreateUserCommand.new

# Or register a block as a command directly
application.register "foo" do |input, output, cmd|
  # Do stuff

  ACON::Command::Status::SUCCESS
end

# Run the application.
# By default this uses STDIN and STDOUT for its input and output.
application.run
```

### Entrypoint

The console component best works in conjunction with a dedicated Crystal file that'll be used as the entry point.
Ideally this file is compiled into a dedicated binary for use in production, but is invoked directly while developing.
Otherwise, any changes made to the files it requires would not be represented.
The most basic example would be:

```
#!/usr/bin/env crystal

# Require the component and anything extra needed based on your business logic.
require "athena-console"

application = ACON::Application.new "My CLI"

# Add any commands defined externally,
# or configure/customize the application as needed.

application.run
```

The [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) allows executing the file as a command without needing the `crystal` prefix.
For example `./console list` would list all commands.

### Console Completion

Athena's completion script can be installed to provide auto tab completion out of the box for command and option names, and values in some cases.
The script currently supports the shells: `bash` (also requires the `bash-completion` package), `fish`, and `zsh`.
Run `./console completion --help` for installation instructions based on your shell.

NOTE: The completion script only needs to be installed _once_, but is specific to the binary used to generate it.
E.g. `./console completion` would be scoped to the `console` binary, while `./myapp completion` would be scoped to `myapp`.

Once installed, restart your terminal, and you should be good to go!

WARNING: The completion script may only be used with real built binaries, not temporary ones such as `crystal run src/console.cr -- completion`.
This is to ensure the performance of the script is sufficient, and to avoid any issues with the naming of the temporary binary.

## Learn More

* Asking [ACON::Question][]s
* Reusable output [styles][Athena::Console::Formatter::OutputStyleInterface]
* High level reusable formatting [styles][Athena::Console::Style::Interface]
* [Testing abstractions][Athena::Console::Spec]
* [Tab Completion][Athena::Console::Input::Interface--argumentoption-value-completion]
* Rendering [ACON::Helper::Table][]s, [ACON::Helper::ProgressBar][]s, or [ACON::Helper::ProgressIndicator][]s
* The various [Verbosity Levels][ACON::Output::Verbosity]
