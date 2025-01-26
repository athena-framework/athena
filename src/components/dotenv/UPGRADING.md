# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.2.0

### Normalization of Exception types

The namespace exception types live in has changed from `ACON::Exceptions` to `ACON::Exception`.
Any usages of `console` exception types will need to be updated.

Some additional types have also been removed/renamed:

* `ACON::Exceptions::ConsoleException` has been removed in favor of using `ACON::Exception` directly
* `ACON::Exceptions::RuntimeError` has been renamed `ACON::Exception::Runtime`
* `ACON::Exceptions::ValidationError` has been removed with past usages now raising an `ACON::Exception::Runtime` error

If using a `rescue` statement with a parent exception type, either from the `console` component or Crystal stdlib, double check it to ensure it'll still rescue what you are expecting it will.
