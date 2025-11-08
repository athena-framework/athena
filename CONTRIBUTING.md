# Contributing

First off, thank you for taking the time to contribute! Athena, and many other open source projects, would not be the same without you!

The following is intended to be a living document describing the guidelines for contributing to Athena, and its components. Athena makes use of the monorepo pattern, with each component having its own read only repository. As such, all contributions should directed towards this repository.

## Start Here

Find something that isn't working as expected? Have an idea for a new feature/enhancement? Want to improve the documentation?

If you answer "Yes" to any of these, you've come to the right place! The first step is to search through the current [issues](https://github.com/athena-framework/athena/issues) and [pull requests](https://github.com/athena-framework/athena/pulls) to see if it has already been reported and/or resolved. If your search comes up empty then feel free to create an issue, or if you're still not sure if you should make one, stop by the [Discord](https://discord.gg/TmDVPb3dmr) server to ask just to be sure; even if the answer is most likely always going to be yes.

## Issue Tracker

The [issue tracker](https://github.com/athena-framework/athena/issues) is the heart of the Athena. Use it for bugs, questions, proposals, and feature requests.

Please always **open a new issue before sending a pull request** if you want to add a new feature to Athena, unless it is a minor obvious fix, or is in relation to an already open & approved issue. This reduces the likelihood of wasted effort, and ensures the end result is robust by being able to work out implementation details _before_ the work is started.

## Local Development

Before staring any local development, be sure to [fork](https://github.com/athena-framework/athena/fork) the repo, then create a branch to use for the related approved issue you're working on.

Due to Athena's usage of a monorepo, the same single repo can be used to contribute code to all components.

In addition to Crystal itself, Athena makes use of [just](https://just.systems/man/en/introduction.html) as its command runner.
`just` provides a simple way of executing common commands needed for development.

Once you have it installed, and have cloned the monorepo, first install all the shard dependencies by running:

```sh
just install
```

And that's it, you are now ready to start coding!
From here there are some additional optional tools that will come in handy:

1. [typos](https://github.com/crate-ci/typos) - Source code spell checker, used as part of the `spellcheck` recipe.
1. [watchexec](https://github.com/watchexec/watchexec) - Executes commands in response to file modifications, used as part of the `watch` and `watch-spec` recipes.
1. [kcov](https://github.com/SimonKagstrom/kcov) - Code coverage tool, used to generate coverage reports/files as part of the `test` recipes.
1. [changie](https://changie.dev/) - Changelog management tool, used as part of the `change` recipe.
1. [uv](https://docs.astral.sh/uv/) - Python package manager, used for the `docs` related recipes.

**TIP:** Running `just` will provide a summary of available recipes.

### Development

Because of Athena's usage of a monorepo some interactions may be different than a normal shard.
Mainly that most things can be done from the root of the repo; no need to `cd` to whatever component you're working on, and need to go through `just`.

For exploratory work, the suggested workflow is to have your code in the related component's entry point file.
E.g. `src/components/clock/src/athena-clock.cr` for the `clock` component.
From here you can run `just watch clock` and that will re-run the file when changes are made.
This makes it simple to play around with early implementations before there is proper test coverage.

#### Testing

Similar to development itself, running the specs are also done through `just`: `just test clock` would run the spec suite for that component, and generate coverage information if you have `kcov` installed.
The `watch-test` recipe can come in handy to provide quicker feedback while the tests are under development.

##### Athena Spec

Many Athena components make use of [Athena Spec](https://athenaframework.org/Spec/) for their unit/integration tests. This library provides an alternate DSL that is 100% compatible with the standard library's `Spec` module. I.e. they can be used together seamlessly, using whatever DSL is more appropriate for what is being tested. Being familiar with  the base [ASPEC::TestCase](https://athenaframework.org/Spec/TestCase/) type will not only make reading the specs easier, but writing them as well. It comes with various features to make the tests simpler, reusable, and extensible. You may even want to use it in your own projects :wink:.

### Linting

Beyond testing, Athena makes use of various forms of linting, including:

* [ameba](https://github.com/crystal-ameba/ameba) for static code analysis
* [typos](https://github.com/crate-ci/typos) for spell checking
* The Crystal [formatter](https://crystal-lang.org/reference/guides/writing_shards.html#coding-style) for code formatting

All of these can be executed at once via the `just lint` recipe, but may also be ran individual as needed via their related `just` recipe.

### Documentation

Athena's [documentation](https://athenaframework.org/) site may be built locally via the `just build-docs` recipe.
Alternatively, a live-updating server may be started via the `just serve-docs` recipe.

## Opening a PR

At this point the code on your branch should have a passing test suite, including linting/spellchecking, and updated documentation if applicable. From here the only step left is to open a PR.

> **NOTE:** Once the PR is opened, please avoid force-pushing to that branch.

Athena comes with a PR template that should be filled out; being sure to reference the issue number in the context section. E.g. `Resolves #xxx`.
The changelog section should include all changes, both internal and external being sure to highlight breaking changes by prefixing the line with `**Breaking:**`.
Additionally, changes that affect end users should also have a `changie` change file. These can most easily be created by following along the prompts of `just change`.
Project maintainers can add the file(s) themselves if needed to move things along; just being sure to give proper attribution in the change file.

> **NOTE:** As of now you'll need to open the PR _before_ creating the change file in order to know what the PR number is.
