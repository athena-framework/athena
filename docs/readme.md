# Documentation

Athena takes a modular approach to its feature set.  Each feature is encapsulated in its own module; and can be required independently of each other.  This allows an application to only include what that application needs, without extra bloat.

* [Routing](./routing.md) `require "athena/routing"` - _done_:
  * [Defining routes](./routing.md#defining-routes)
  * [Defining Query Params](./routing.md#query-params)
  * [Defining life-cycle callbacks](./routing.md#request-life-cycle-events)
  * [Manage response serialization](./routing.md#route-view)
  * [Param conversion](./routing.md#paramconverter)
  * [Static File Handling](./routing.md#static-file-handling)
* [CLI](./cli.md) `require "athena/cli"` - _done_:
  * [Creating CLI commands](./cli.md#commands)
* Security - _todo_:
  * TBD
* Documentation - _todo_:
  * TBD






