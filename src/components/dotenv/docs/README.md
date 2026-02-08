The `Athena::Dotenv` component parses the `.env` files to make ENV vars stored within them accessible.
Using [Environment variables](https://en.wikipedia.org/wiki/Environment_variable) (ENV vars) is a common practice to configure options that depend on where the application is run;
allowing the application's configuration to be de-coupled from its code.
E.g. anything that changes from one machine to another, such as database credentials.

`.env` files are a convenient way to get the benefits of ENV vars, without taking on the extra complexity of other tools/abstractions until if/when they are needed.
The file(s) can be defined at the root of your project for development, or placed next to the binary if running outside of a dev environment.

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-dotenv:
    github: athena-framework/dotenv
    version: ~> 0.2.0
```

## Usage

In most cases all that needs to be done is:

```crystal
require "athena-dotenv"

# For most use cases, returns a `Athena::Dotenv` instance.
dotenv = Athena::Dotenv.load # Loads .env

# Multiple files may also be loaded if needed
Athena::Dotenv.load ".env", ".env.local"
```


For more complex setups, the [Athena::Dotenv](/Dotenv/top_level/) instance can be manually instantiated.
E.g. to use the other helper methods such as [#load_environment](</Dotenv/top_level/#Athena::Dotenv#load_environment(path,env_key,default_environment,test_environments,override_existing_vars)>), [#overload](</Dotenv/top_level/#Athena::Dotenv#overload(*)>), or [#populate](</Dotenv/top_level/#Athena::Dotenv#populate(values,override_existing_vars)>)

```crystal
require "athena-dotenv"

dotenv = Athena::Dotenv.new

# Overrides existing variables
dotenv.overload ".env.overrides"

# Load all files for the current $APP_ENV
# .env, .env.local, and .env.$APP_ENV.local or .env.$APP_ENV
dotenv.load_environment ".env"
```

[Athena::Dotenv::Exception::Path](/Dotenv/Exception/Path/) error will be raised if the provided file was not found, or is not readable.
