# README

Template repo for creating a new Athena component. Scaffolds the Crystal shard's structure as well as define CI etc.

**NOTE:** This repo assumes the component will be in the `athena-framework` org.  If it is to be used outside of the org, be sure to update URLs accordingly.

1. Find/replace `COMPONENT_NAME` with the name of the component.  This is used as the shard's name.  E.x. `logger`.
  1.1 Be sure to rename the file in `./src` as well.

1. Replace `NAMESPACE_NAME` with the name of the component's namespace.  Documentation for this component will be grouped under this. E.x. `Logger`.

1. Find/replace `CREATOR_NAME` with your Github display name. E.x. `George Dietrich`.

1. Find/replace `CREATOR_USERNAME` with your Github username. E.x. `blacksmoke16`.

1. Find/replace `CREATOR_EMAIL` with your desired email

   5.1 Can remove this if you don't wish to expose an email.

1. Find/replace `ALIAS_NAME` with the three letter alias for this component; A + 2 letter shortcut to `NAMESPACE_NAME`.  E.x. `ALG`.

1. Find/replace `DESCRIPTION` with a short description of what the component does.

1. Add some initial documentation to `docs/README.md`.

Delete from here up
# NAMESPACE_NAME

[![Common Changelog](https://common-changelog.org/badge.svg)](https://common-changelog.org)
[![CI](https://github.com/athena-framework/athena/workflows/CI/badge.svg)](https://github.com/athena-framework/athena/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/release/athena-framework/COMPONENT_NAME.svg)](https://github.com/athena-framework/COMPONENT_NAME/releases)

DESCRIPTION.

## Getting Started

Checkout the [Documentation](https://athenaframework.org/NAMESPACE_NAME).

## Contributing

Read the general [Contributing Guide](./CONTRIBUTING.md) for information on how to get started.
