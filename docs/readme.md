# Documentation

Athena takes a modular approach to its feature set.  Each feature is encapsulated in its own module; and can be required independently of each other.  This allows an application to only include what that application needs, without extra bloat.

## The `athena` executable

Upon install, Athena will build and add an `athena` executable to your projects `bin` directory.  This binary can be used to run Athena related commands, all of which are listed in the [docs](<https://blacksmoke16.github.io/athena/Athena/Commands.html>).

## Configuration

Athena uses a YAML file to store settings related to the application, called `athena.yml`.  If a config file was not created upon installing Athena, an example file is available [here](https://github.com/Blacksmoke16/athena/blob/master/athena.yml), which also contains the default values.  There is also a command in the `athena` executable that is able to generate the configuration file with the default values. 

>  `./bin/athena -c athena:generate:config_file`

The configuration file path can be changed by setting the value of `ATHENA_CONFIG_PATH` environment variable to the desired path.  The path defaults to the root of your project.

By default, the configuration file contains the default settings for the `development` environment in addition to the other two standard environments: `test` and `production`.  The `test` and `production` environments inherit the settings of the `development` environment.  However, environment specific settings can be defined by simply changing the values that you wish to be changed.

```yaml
---
environments:
  development: &development
    routing:
      cors:
        enabled: true
        strategy: blacklist
        defaults: &defaults
          allow_origin: https://api.dev.yourdomain.com
          expose_headers: []
          max_age: 0
          allow_credentials: false
          allow_methods: []
          allow_headers: []
        groups: {}
  test: &test
    <<: *development
  production: &production
    <<: *development
    routing:
      cors:
        defaults:
          allow_origin: https://api.yourdomain.com
```

This would inherit the settings from the `development` environment, but change the `allow_origin` domain for the `production` environment.

### Environments
Athena uses the environmental variable `ATHENA_ENV` to determine the current environment.  This variable determines which log handlers are enabled by default, and which configuration object to use.  If no ENV variable is defined, the default environment is `development`. The method `Athena.environment` can be used to return the application's current environment.  Custom environments can also be used, just be sure to update your `athena.yml`.  

### Accessing the Configuration

The `Athena.config` method will return an [`Athena::Config::Config`](<https://blacksmoke16.github.io/athena/Athena/Config/Config.html>) object instantiated from the `athena.yml` file based on the application's current environment.  This method allows the application's configuration to be usable from within HTTP handlers, CLI commands, etc.  

### Custom Settings

The Athena configuration file can also be used to store application specific settings by using the `custom_settings` object.  Custom settings can also be configured on a per environment basis just like the CORS settings.

```yaml
# Config file for Athena.
---
environments:
  development: &development
    ...
    custom_settings:
      gold_multiplier: 10.0
      aws:
        username: username
        password: password
  production: &production
    <<: *development
    custom_settings:
      gold_multiplier: 1.0
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

This, combined with the `Athena.config` method, would allow for these to be used within the application.  The value of the `gold_multiplier`, in this example, would be dependent on the current environment.

```crystal
gold = player.gold * Athena.config.custom_settings.gold_multiplier
aws_client = Athena.config.custom_settings.aws.get_client
```

**NOTE:** There are no safety measures around the `custom_settings` object.  Be sure to properly type the getters, make sure the properties are included in the config file, or use defaults values if needed.  Runtime exceptions will be thrown if a key is missing that doesn't have a default value, or if the `custom_settings` key isn't defined in the configuration file.

## Logging

Athena utilizes [Crylog](https://github.com/blacksmoke16/crylog) as its logging solution.  The default logging configuration depends on the current environment.  In the `development` environment Athena will log messages to `logs/development.log` as well as `STDOUT`.  The `production` environment will log to `logs/production.log` but only for warnings or higher.  Logging is disabled within the `test` environment.

### Using the logger

The default logger can be retrieved via the `Athena.logger` method, which wraps `Crylog.logger(channel : String)` for convenience.  For additional usage information, take a look at the [Crylog Documentation](https://github.com/Blacksmoke16/crylog/tree/master/docs#logger).

```crystal
user = ...

main_logger = Athena.logger
other_logger = Athena.logger "other"

main_logger.info "User logged in", Crylog::LogContext{"name" => user.name, "id" => user.id}
other_logger.emergency "DB is down!"
```

### Custom Logger

If you wish to customize the logger(s) for your application, you can override the `Athena.configure_logger` method.

```crystal
protected def Athena.configure_logger
  Crylog.configure do |registry|
    # Configure your loggers
  end
end
```

For additional usage information on the configuration options, take a look at the [Crylog Documentation](https://github.com/Blacksmoke16/crylog/tree/master/docs).

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
* [Dependency Injection](./dependency_injection.md) `require "athena/di"` - done:
  * [Registering Services](./dependency_injection.md#registering-services)
  * [Retrieving Services](./dependency_injection.md#retrieving-services)
  * [Auto Injection](./dependency_injection.md#auto-injection)
* Security - _todo_:
  * TBD
* Documentation - _todo_:
  * TBD






