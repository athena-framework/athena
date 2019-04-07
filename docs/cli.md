# CLI

## Commands

Athena makes it easy to define CLI commands.  These commands are included when you build your program; which can be used for data migration, disable/enable user accounts, or other commonly used developer related tasks with the added benefit of being testable, reusable and can be documented.

A command is created by defining a struct that inherits from `Athena::Cli::Command`.

```Crystal
require "athena/cli"

struct MigrateEventsCommand < Athena::Cli::Command
  self.name = "migrate:events"
  self.description = "Migrates legacy events for a given customer"

  def self.execute(customer_id : Int32, event_ids : Array(Int64)) : Nil
    # Do stuff for the migration
    # Params are converted from strings to their expected types
  end
end
```

Then in your main app file, call `Athena::Cli.register_commands`.  This will define an `option_parser` interface to interact with your commands, including: listing available commands, and running a command.  Executing your binary without any arguments will run your program normally.

```Crystal
require "athena/cli"
# other requires

module MyApp
  # Other app setup

  Athena::Cli.register_commands

  MyApp.run
end
```

Then, after building the program.

```bash
./MyApp -c migrate:events --customer_id=83726 --event_ids=1,2,3,4,5
./MyApp -l
Registered commands:
	migrate
		migrate:events - Migrates legacy events for a given customer
```

the `-l` or `--list` argument will list the available commands that can be executed via the binary.  The commands are grouped based on the first part of the command name, separated by `:`.  The `-e NAME` or `--explain NAME` can be used to get more detailed information about a given command.

```bash
./MyApp -e migrate:events
Command
	migrate:events - Migrates legacy events for a given customer
Usage
	./YOUR_BINARY -c migrate:events [arguments]
Arguments
	customer_id : Int32
	event_ids : Array(Int64)
```

### Parameters

The name and type of each parameter in a command's `self.execute` method are used to define the name of the arguments that will be read from the command line, as well as if that parameter is required or optional.  

### Supported Types

All primitive data types are supported including:  `Int32`, `Bool`, `Float64`, etc.  Array types are also supported and should be inputted as a comma separated list of values.  

### Required/Optional Parameters

Non-nilable parameters are considered required and will raise an exception if not supplied, without a default value.  Nilable parameters are considered optional and will be nil if not supplied, without a default value.



