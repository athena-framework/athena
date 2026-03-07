# Athena Bundle Template

Template repo for creating a new Athena bundle. Scaffolds the Crystal shard's structure.

> **NOTE:** This repo assumes the bundle will be in the `athena-framework` org.
If it is to be used outside of the org, be sure to update URLs accordingly and setup CI.

1. Find/replace `BUNDLE_NAME` with the name of the bundle. This is used as the shard's/repo name.  E.x. `logger`, NOT `logger-bundle`
  1.1 Be sure to rename the file in `./src` as well.

1. Replace `NAMESPACE_NAME` with the name of the component's namespace. Documentation for this component will be grouped under this. E.x. `LoggerBundle`.

1. Find/replace `CREATOR_NAME` with your Github display name. E.x. `George Dietrich`.

1. Find/replace `CREATOR_USERNAME` with your Github username. E.x. `blacksmoke16`.

1. Find/replace `CREATOR_EMAIL` with your desired email
   5.1 Can remove this if you don't wish to expose an email.

1. Find/replace `DESCRIPTION` with a short description of what the component does.

1. Add some initial documentation to `docs/README.md`.

1. Specify the `athena-dependency_injection` dependency's supported version(s). E.x. `version: ~> 0.4`

Delete from here up
# NAMESPACE_NAME

[![Common Changelog](https://common-changelog.org/badge.svg)](https://common-changelog.org)
[![CI](https://github.com/athena-framework/athena/workflows/CI/badge.svg)](https://github.com/athena-framework/athena/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/release/athena-framework/BUNDLE_NAME-bundle.svg)](https://github.com/athena-framework/BUNDLE_NAME-bundle/releases)

DESCRIPTION.

## Getting Started

Checkout the [Documentation](https://athenaframework.org/NAMESPACE_NAME).

## Contributing

Read the general [Contributing Guide](./CONTRIBUTING.md) for information on how to get started.
