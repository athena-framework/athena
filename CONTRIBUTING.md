# Contributing

First off, thank you for taking the time to contribute! Athena, and many other open source projects, would not be the same without you!

The following is intended to be a living document describing the guidelines for contributing to Athena, and its components. Athena makes use of the monorepo pattern, with each component having its own read only repository. As such, all contributions should directed towards this repository.

## Start Here

Find something that isn't working as expected? Have an idea for a new feature/enhancement? Want to improve the documentation?

If you answer "Yes" to any of these, you've come to the right place! The first step is to search through the current [issues](https://github.com/athena-framework/athena/issues) and [pull requests](https://github.com/athena-framework/athena/pulls) to see if it has already been reported and/or resolved. If your search comes up empty then feel free to create an issue, or if you're still not sure if you should make one, stop by the [Discord](https://discord.gg/TmDVPb3dmr) server to ask just to be sure; even if the answer is most likely always going to be yes.

## Issue Tracker

The [issue tracker](https://github.com/athena-framework/athena/issues) is the heart of the Athena. Use it for bugs, questions, proposals, and feature requests.

Please always **open a new issue before sending a pull request** if you want to add a new feature to Athena, unless it is a minor obvious fix, or is in relation to an already open & approved issue. This reduces the likelihood of wasted effort, and ensures the end result is robust by being able to work out implementation details _before_ the work is started.

## Testing

Due to Athena's usage of a monorepo, testing is handled slightly differently than with a normal shard. Mainly that all testing is done directly from the root of the monorepo itself. Athena's `./scripts/test.sh` helper script can be used to make this easier by providing a singular entrypoint that defines all of the common options and flags needed to run the tests for all, or a single component. However, before it can be used the components themselves need installed.

Shards are ideally installed via symlink, which allows for updates to be instantly available for testing without having to juggle branches/edit each component's `shard.yml`. The `shard.dev.yml` file can be used in conjunction with the `SHARDS_OVERRIDE` environmental variable for this purpose:

```sh
$ SHARDS_OVERRIDE=shard.dev.yml shards update
```

From here, the tests for a specific component may be ran via the helper script:

```sh
$ ./scripts/test.sh routing
```

Or alternateively, for all components:

```sh
$ ./scripts/test.sh
```

Athena also leverages [ameba](https://github.com/crystal-ameba/ameba) as its form of static code analysis. It too can be ran directly from the root of the monorepo after the required shards are installed:

```sh
$ ./bin/ameba
```

### Athena Spec

Many Athena components make use of [Athena Spec](https://athenaframework.org/Spec/) for their unit/integration tests. This library provides an alternate DSL that is 100% compatible with the standard library's `Spec` module. I.e. they can be used together seamlessly, using whatever DSL is more appropriate for what is being tested. Being familiar with  the base [ASPEC::TestCase](https://athenaframework.org/Spec/TestCase/) type will not only make reading the specs easier, but writing them as well. It comes with various features to make the tests simpler, reusable, and extensible. You may even want to use it in your own projects :wink:.
