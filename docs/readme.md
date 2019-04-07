# Documentation

Athena takes a modular approach to its feature set.  Each feature is encapsulated in its own module; and can be required independently of each other.  This allows an application to only include what that application needs, without extra bloat.

## The `athena` executable

Upon install, Athena will build and add an `athena` executable to your projects `bin` directory.  This binary can be used to run Athena related commands, all of which are listed in the [docs](<https://blacksmoke16.github.io/athena/Athena/Commands.html>).

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






