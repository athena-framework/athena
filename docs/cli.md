# CLI Commands

Athena makes it easy to define custom CLI commands.

## Creating Commands

A command is created by creating a struct that inherits from `Athena::Cli::Command`.

```Crystal
require "athena/cli"

struct MigrateEventsCommand < Athena::Cli::Command
  self.command_name = "migrate:events"
  self.description = "Migrates legacy events for a given customer"

  def self.execute(customer_id : Int32, event_ids : Array(Int64)) : Nil
    # Do stuff for the migration
  end
end
```

Then in your main app file, call `Athena::Cli.register_commands`.  This will define an option_parser interface to interact with your commands, including: listing available commands, and running a command.  Executing your binary without any commands will run it normally.

```Crystal
require "athena/cli"

module MyApp
  # Other app setup/requires

  Athena::Cli.register_commands

  MyApp.run
end

./MyApp -c migrate:events --customer_id=83726 --event_ids=1,2,3,4,5
./MyApp -l
Registered commands:
	migrate:events - Migrates legacy events for a given customer
```

### Parameters

The name and type of each parameter in a command's `self.execute` method are used to define the name of the arguments that will be read from the command line, as well as if that parameter is required or optional.  

### Supported Types

All primitive data types are supported including:  `Int32`, `Bool`, `Float64`, etc.  Array types are also supported should be inputted as a comma separated list of values.  

### Required/Optional Parameters

Non-nilable parameters are considered required and will raise an exception if not supplied.  Nilable parameters are considered optional and will be nil if not supplied.



