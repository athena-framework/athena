# Documentation

Athena takes a modular approach to its feature set.  Each feature is encapsulated in its own module; and can be required independently of each other.  This allows an application to only include what that application needs, without extra bloat.

## The `athena` executable

Upon install, Athena will build and add an `athena` executable to your projects `bin` directory.  This binary can be used to run Athena related commands, all of which are listed in the [docs](<https://blacksmoke16.github.io/athena/Athena/Commands.html>).

## Configuration

Athena uses a YAML file in the root of your application to store settings related to the application, called `athena.yml`.  Currently, the main use of this file is for [Handling CORS](./routing.md#cors).  However, in the future additional configuration options will be added.  If a config file was not created upon installing Athena, created before it was added automatically for example, an example file is available [here](https://github.com/Blacksmoke16/athena/blob/master/athena.yml). 

### Accessing the Configuration

The `Athena.config` method will return an [`Athena::Config::Config`](<https://blacksmoke16.github.io/athena/Athena/Config/Config.html>) object instantiated from the `athena.yml` file.  The method also accepts a *config_path* parameter that returns the config from file at the end of the path.  This method allows the application's configuration to be usable from within HTTP handlers, CLI commands, etc.  

A recommended option is to have multiple config files for each environment, then use an ENV variable that determines which one to use. 

```crystal
config = Athena.config "athena_#{ENV["ENV"].downcase}.yml"
```

### Custom Settings

The Athena configuration file can also be used to store application specific settings by using the `custom_settings` object.

```yaml
# Config file for Athena.
---
...
custom_settings:
  gold_multiplier: 2.0
  aws:
    username: username
    password: password
```

The specific settings are defined by creating a `CustomSettings` struct in your application.  Getters defined on this struct will be read from the configuration file's `custom_settings` object.  Methods and nested objects can also be used.  

```crystal
struct Aws
  # CrSerializer _MUST_ be included on nested objects.
  include CrSerializer(YAML)

  getter username : String
  getter password : String
   
  def get_client : AwsClient
    AwsClient.new @username, @password
  end
end

struct CustomSettings
  getter gold_multiplier : Float64
  getter aws : Aws
end
```

This, combined with the `Athena.config` method, would allow for these to be used within the application.

```crystal
gold = player.gold * Athena.config.custom_settings.gold_multiplier
aws_client = Athena.config.custom_settings.aws.get_client
```

**NOTE:** There are no safety measures around the `custom_settings` object.  Be sure to properly type the getters, make sure the properties are included in the config file, or use defaults values if needed.  Exceptions will be thrown if a key is missing that doesn't have a default value, or if the `custom_settings` key isn't defined in the configuration file.

## Modules

* [Routing](./routing.md) `require "athena/routing"` - _done_:
  * [Defining routes](./routing.md#defining-routes)
  * [Exception Handling](./routing.md#exception-handling)
  * [Defining Query Params](./routing.md#query-params)
  * [Defining life-cycle callbacks](./routing.md#request-life-cycle-events)
  * [Manage response serialization](./routing.md#route-view)
  * [Param conversion](./routing.md#paramconverter)
  * [Handling CORS](./routing.md#cors)
  * [Custom HTTP Handlers](./routing.md#custom-handlers)
* [CLI](./cli.md) `require "athena/cli"` - _done_:
  * [Creating CLI commands](./cli.md#commands)
* Security - _todo_:
  * TBD
* Documentation - _todo_:
  * TBD






