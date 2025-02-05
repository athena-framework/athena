# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.4.0

### New `ACON::Output::Verbosity::SILENT` verbosity level

Existing commands that define a `--silent` option will have to be renamed.

### Normalization of Exception types

The namespace exception types live in has changed from `ACON::Exceptions` to `ACON::Exception`.
Any usages of `console` exception types will need to be updated.

Some additional types have also been removed/renamed:

* `ACON::Exceptions::ConsoleException` has been removed in favor of using `ACON::Exception` directly
* `ACON::Exceptions::RuntimeError` has been renamed `ACON::Exception::Runtime`
* `ACON::Exceptions::ValidationError` has been removed with past usages now raising an `ACON::Exception::Runtime` error

If using a `rescue` statement with a parent exception type, either from the `console` component or Crystal stdlib, double check it to ensure it'll still rescue what you are expecting it will.

## Upgrade to 0.3.6

### `ACON::Application` version is now represented as a `String`

If passing a [SemanticVersion](https://crystal-lang.org/api/SemanticVersion.html) as the *version* of an `ACON::Application`, call `#to_s` on it or ideally pass a semver `String` directly.
If using the `#version` getter off the `ACON::Application`, your code will need to adapt to it now being a `String`.
Either by manually constructing a `SemanticVersion` or ideally just supporting the returned `String`.

## Upgrade to 0.3.3

### New `ACON::Style::Interface` methods

If implementing a custom style, you will now need to implement the following methods:

- `abstract def progress_start(max : Int32? = nil) : Nil`
- `abstract def progress_advance(by step : Int32 = 1) : Nil`
- `abstract def progress_finish : Nil`

These should use an internal `ACON::Helper::ProgressBar` customized to fit your style that delegates to the related methods.
