The `Athena::DependencyInjection` component provides a robust dependency injection service container framework.
Some of the reasoning for how this can/would be useful is called out in the [Why Athena?](/why_athena) page.

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-dependency_injection:
    github: athena-framework/dependency-injection
    version: ~> 0.3.0
```

## Usage

A special class called the `ADI::ServiceContainer` (SC) stores useful objects, aka services, that can be shared throughout the project.
The SC is lazily initialized on fibers; this allows the SC to be accessed anywhere within the project.
The [ADI.container][] method will return the SC for the current fiber.

If you are a user of a project/framework making use of this component, checkout [ADI::Register][] as most of all the information you need is documented there.

Otherwise, if you are the creator/maintainer of a project wishing to integrate this component,
the best way to integrate/use this component depends on the execution flow of your application, and how it uses [Fibers](https://crystal-lang.org/api/Fiber.html).
Since each fiber has its own container instance, if your application only uses Crystal's main fiber and is short lived, then you most likely only need to set up your services
and expose one of them as [public][Athena::DependencyInjection::Register--optional-arguments] to serve as the entry point.

If your application is meant to be long lived, such as using a [HTTP::Server](https://crystal-lang.org/api/HTTP/Server.html), then you will want to ensure that each
fiber is truly independent from one another, with them not being reused or sharing state external to the container.
An example of this is how `HTTP::Server` reuses fibers for `connection: keep-alive` requests.
Because of this, or in cases similar to, you may want to manually reset the container via `Fiber.current.container = ADI::ServiceContainer.new`.

