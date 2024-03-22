Athena Framework does not have any other dependencies outside of Crystal and Shards.
It is designed in such a way to be non-intrusive and not require a strict organizational convention in regards to how a project is setup;
this allows it to use a minimal amount of setup boilerplate while not preventing it for more complex projects.

## Install Athena Framework

Add the framework component to your `shard.yml`:

```yaml
dependencies:
  athena:
    github: athena-framework/framework
    version: ~> 0.18.0
```

Then run `shards install`.
This will install the framework component and its required component dependencies.
Finally require it via `require "athena"`, then are all set to starting using the framework, starting with [Routing & HTTP](./routing.md).

TIP: Check out the [skeleton](https://github.com/athena-framework/skeleton) template repository to get up and running quickly.
