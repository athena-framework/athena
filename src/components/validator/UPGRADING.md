# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.4.0

### New `AVD::Constraints::URL#require_tld` option

`AVD::Constraints::URL` now requires URLs have a TLD by default; `https://example.com` is valid while `https://example` is not.
If your logic requires the latter to be considered valid, you will need to ensure `require_tld` is set to `false` on usages of this constraint.

### Normalization of Exception types

The namespace exception types live in has changed from `AVD::Exceptions` to `AVD::Exception`.
Any usages of `validator` exception types will need to be updated.

Some additional types have also been removed/renamed:

* `AVD::Exceptions::ValidatorError` has been removed in favor of using `AVD::Exception` directly

If using a `rescue` statement with a parent exception type, either from the `validator` component or Crystal stdlib, double check it to ensure it'll still rescue what you are expecting it will.
