# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.4.0

### Normalization of Exception types

The namespace exception types live in has changed from `ASR::Exceptions` to `ASR::Exception`.
Any usages of `serializer` exception types will need to be updated.

Some additional types have also been removed/renamed:

* `ASR::Exceptions::SerializerException` has been removed in favor of using `ASR::Exception` directly

If using a `rescue` statement with a parent exception type, either from the `serializer` component or Crystal stdlib, double check it to ensure it'll still rescue what you are expecting it will.
