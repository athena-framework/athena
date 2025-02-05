# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.2.0

### Normalization of Exception types

The namespace exception types live in has changed from `Athena::Dotenv::Exceptions` to `Athena::Dotenv::Exception`.
Any usages of `dotenv` exception types will need to be updated.

If using a `rescue` statement with a parent exception type, either from the `console` component or Crystal stdlib, double check it to ensure it'll still rescue what you are expecting it will.
