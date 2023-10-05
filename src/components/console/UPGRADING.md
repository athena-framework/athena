# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to x.x.x

### New `ACON::Style::Interface` methods

If implementing a custom style, you will now need to implement the following methods:

- `abstract def progress_start(max : Int32? = nil) : Nil`
- `abstract def progress_advance(by step : Int32 = 1) : Nil`
- `abstract def progress_finish : Nil`

These should use an internal `ACON::Helper::ProgressBar` customized to fit your style that delegates to the related methods.
