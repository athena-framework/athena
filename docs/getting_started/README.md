Outside of Crystal and Shards, Athena Framework only depends on `libmagic`, see [System Dependencies](#system-dependencies).
It is designed in such a way to be non-intrusive and not require a strict organizational convention in regards to how a project is setup;
this allows it to use a minimal amount of setup boilerplate while not preventing it for more complex projects.

## Install Athena Framework

Add the framework component to your `shard.yml`:

```yaml
dependencies:
  athena:
    github: athena-framework/framework
    version: ~> 0.23.0
```

Then run `shards install`.
This will install the framework component and the components it requires: [Dependency Injection](/DependencyInjection/), [Event Dispatcher](/EventDispatcher/), [HTTP](/HTTP/), [HTTP Kernel](/HTTPKernel/), and [Routing](/Routing/), along with [Contracts](/Contracts/) and [MIME](/MIME/).
Finally require it via `require "athena"`, then you are all set to starting using the framework, starting with [Routing & HTTP](./routing.md).

TIP: Check out the [skeleton](https://github.com/athena-framework/skeleton) template repository to get up and running quickly.

### Optional Components

Other components are only installed, and integrated into the framework, when an application needs them.
To use one, add it to your `shard.yml` alongside the framework, then require it as shown below.
Components that integrate via a [bundle](./configuration.md#bundles) are registered by requiring their bundle.

| Component                    | Require                   | Adds                                                                                                      |
| ---------------------------- | ------------------------- | --------------------------------------------------------------------------------------------------------- |
| [Clock](/Clock/)             | `athena-clock`            | The `clock` service, injectable via `ACLK::Interface`                                                     |
| [Console](/Console/)         | `athena-console/bundle`   | [Commands](./commands.md) registered as services and run via `ATH.run_console`, plus built-in debug commands |
| [Mercure](/Mercure/)         | `athena-mercure/bundle`   | Pushing updates to web browsers and other HTTP clients via a Mercure hub                                  |
| [Negotiation](/Negotiation/) | `athena-negotiation`      | [Content negotiation](./routing.md#content-negotiation) via the format listener                           |
| [ORM](/ORM/)                 | `athena-orm/bundle`       | Persisting entities to a database via an entity manager                                                   |
| [Serializer](/Serializer/)   | `athena-serializer/bundle` | (De)serializing `ASR::Serializable` types, including serialization groups and versions                   |
| [Validator](/Validator/)     | `athena-validator/bundle` | [Validating](./validation.md) request bodies, query strings, and uploaded files                           |

Other components, such as [Dotenv](/Dotenv/) or [Spec](/Spec/), can be used alongside the framework as is.

### System Dependencies

On top of the libraries Crystal itself needs, such as PCRE2, and OpenSSL and zlib for its HTTP server, the framework links `libmagic` (usually provided by the `file` package) to guess the MIME type of files based on their content.
Some optional components link additional libraries:

| Component                  | Libraries                     | Used For                                        |
| -------------------------- | ----------------------------- | ----------------------------------------------- |
| [Serializer](/Serializer/) | `libyaml`                     | Its YAML support                                |
| [Mercure](/Mercure/)       | GMP and OpenSSL, via the optional `jwt` shard | Generating the JWTs used to authorize with the hub |
| [ORM](/ORM/)               | Those of its database driver, such as `libsqlite3` | Connecting to the database |

Applications that do not need some of these can opt out of them at build time:

* `-Dwithout_libmagic` - MIME types are only guessed based on file extensions, see [AMIME::MagicTypesGuesser](/MIME/MagicTypesGuesser/)
* `-Dwithout_openssl` - [ATH.run](/Framework/#Athena::Framework.run(port,host,reuse_port,ssl_context,*,prepend_handlers)) cannot serve HTTPS, such as when TLS is terminated by a reverse proxy. The [Mercure](/Mercure/Bundle/) component then only supports hubs with a static token
* `-Dwithout_zlib` - Crystal's gzip/deflate support is unavailable

An application built with all three only links PCRE2 and the C runtime libraries Crystal always requires.

### Aliases

Crystal does not have an import system, so the fully qualified names of types can get quite long, such as `Athena::Routing::Annotations::Get`.
To keep them short, each component defines aliases to its namespaces, which are used throughout the documentation.
The ones most commonly used within the framework are:

| Alias            | Namespace                                                  |
| ---------------- | ---------------------------------------------------------- |
| `ATH`            | `Athena::Framework`                                        |
| `ATHA`           | `Athena::Framework::Annotations`                           |
| `ATHR`           | `Athena::Framework::Controller::ValueResolvers`            |
| `ART` / `ARTA`   | `Athena::Routing` / `Athena::Routing::Annotations`         |
| `AHTTP`          | `Athena::HTTP`                                             |
| `AHK`            | `Athena::HTTPKernel`                                       |
| `ADI`            | `Athena::DependencyInjection`                              |
| `AED` / `AEDA`   | `Athena::EventDispatcher` / `Athena::EventDispatcher::Annotations` |
| `ACON` / `ACONA` | `Athena::Console` / `Athena::Console::Annotations`         |
| `ASR` / `ASRA`   | `Athena::Serializer` / `Athena::Serializer::Annotations`   |
| `AVD` / `Assert` | `Athena::Validator` / `Athena::Validator::Annotations`     |

See the [introduction](../README.md) for the alias of each component, and the `Aliases` page of each component in the [API Reference](../api_reference.md) for all of them.
Applications may also define their own private aliases for types they use often within a file:

```crystal
private alias Get = ARTA::Get

class ArticleController < ATH::Controller
  @[Get("/article/{id}")]
  def article(id : Int32) : Int32
    id
  end
end
```
