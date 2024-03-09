## Install Crystal

Athena Framework does not have any other dependencies outside of [Crystal](https://crystal-lang.org) and [Shards](https://crystal-lang.org/reference/the_shards_command/index.html).
As such, before you can get started with using the Athena Framework, you need to ensure they are installed.
Refer to the official [installation guide](https://crystal-lang.org/install/) for instructions for your specific operating system.

## Install Athena Framework

Now that its dependencies are installed, add the framework component to your `shard.yml`:

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

## Conventions

The [Why Athena?](../why_athena.md) page explained some of the reasoning behind the _why_ things are the way they are.
The framework also has a few conventions related to a more organizational point of view.

### Namespaces

The most obvious may be how each component is organized from a namespace perspective.
All component namespaces exist within a common top level `Athena` namespace.
Each component uses additional sub namespaces for organizational reasons, and as a means to have a place for common documentation.

### Aliases

Due to how Athena defines its namespaces, they can require a fair amount of typing due to the longer paths.
To help alleviate this, each component defines one or more top level aliases to reduce the number of characters needed to refer to a component's types.
For example, a controller needs to inherit from the `Athena::Framework::Controller` type, or `ATH::Controller` if using the [ATH](/Framework/aliases#ATH) alias.
Similarly, `Athena::Routing::Annotations::Get` could be shortened to `ARTA::Get` via the [ARTA](/Routing/aliases/#ARTA) alias.

In most cases, the component alias is three or four characters abbreviating the name of the component, always starting with an `A`.
Components that also define numerous annotations may have another alias dedicated to those annotations types.
This alias usually is the component alias with an `A`, short for annotations, suffix. E.g. [ATHA](/Framework/aliases/#ATHA) or [ARTA](/Routing/aliases/#ARTA).
Each component may also define additional aliases if needed, check the `Aliases` page in each component's API docs to see specifically what each component defines.
