Outside of Crystal and Shards, Athena Framework only depends on `libmagic`, see [System Dependencies](#system-dependencies).
It is designed in such a way to be non-intrusive and not require a strict organizational convention in regards to how a project is setup;
this allows it to use a minimal amount of setup boilerplate while not preventing it for more complex projects.

## Install Athena Framework

Add the framework component to your `shard.yml`:

```yaml
dependencies:
  athena:
    github: athena-framework/framework
    version: ~> 0.22.0
```

Then run `shards install`.
This will install the framework component and its required component dependencies.
Finally require it via `require "athena"`, then are all set to starting using the framework, starting with [Routing & HTTP](./routing.md).

TIP: Check out the [skeleton](https://github.com/athena-framework/skeleton) template repository to get up and running quickly.

### System Dependencies

On top of the libraries Crystal itself needs, such as PCRE2, OpenSSL, and zlib, the framework links `libmagic` (usually provided by the `file` package) to guess the MIME type of files based on their content.
Applications that do not need some of these can opt out of them at build time:

* `-Dwithout_libmagic` - MIME types are only guessed based on file extensions, see [AMIME::MagicTypesGuesser](/MIME/MagicTypesGuesser/)
* `-Dwithout_openssl` - [ATH.run](/Framework/#Athena::Framework.run(port,host,reuse_port,ssl_context,*,prepend_handlers)) cannot serve HTTPS, such as when TLS is terminated by a reverse proxy
* `-Dwithout_zlib` - Crystal's gzip/deflate support is unavailable

An application built with all three only links PCRE2 and the C runtime libraries Crystal always requires.
