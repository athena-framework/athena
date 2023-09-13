# README

Template repo for creating a new Athena component. Scaffolds the Crystal shard's structure as well as define CI etc.

**NOTE:** This repo assumes the component will be in the `athena-framework` org.  If it is to be used outside of the org, be sure to update URLs accordingly.

1. Find/replace `COMPONENT_NAME` with the name of the component.  This is used as the shard's name.  E.x. `logger`.
  1.1 Be sure to rename the file in `./src`, and `./spec` as well.

1. Replace `NAMESPACE_NAME` with the name of the component's namespace.  Documentation for this component will be grouped under this. E.x. `Logger`.

1. Find/replace `CREATOR_NAME` with your Github display name. E.x. `George Dietrich`.

1. Find/replace `CREATOR_USERNAME` with your Github username. E.x. `blacksmoke16`.

1. Find/replace `CREATOR_EMAIL` with your desired email

   5.1 Can remove this if you don't wish to expose an email.

1. Find/replace `ALIAS_NAME` with the three letter alias for this component; A + 2 letter shortcut to `NAMESPACE_NAME`.  E.x. `ALG`.

1. Find/replace `DESCRIPTION` with a short description of what the component does.

Delete from here up
# NAMESPACE_NAME

[![CI](https://github.com/athena-framework/athena/workflows/CI/badge.svg)](https://github.com/athena-framework/athena/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/release/athena-framework/COMPONENT_NAME.svg)](https://github.com/athena-framework/COMPONENT_NAME/releases)

DESCRIPTION.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  athena-COMPONENT_NAME:
    github: athena-framework/COMPONENT_NAME
    version: ~> 0.1.0
```

2. Run `shards install`

## Documentation

If using the component on its own, checkout the [API documentation](https://athenaframework.org/NAMESPACE_NAME).
If using the component as part of Athena, also checkout the [external documentation](https://athenaframework.org/components/COMPONENT_NAME).

## Contributing

[Report issues](https://github.com/athena-framework/athena/issues) and send [Pull Requests](https://github.com/athena-framework/athena/pulls) in the [main Athena repository](https://github.com/athena-framework/athena).
