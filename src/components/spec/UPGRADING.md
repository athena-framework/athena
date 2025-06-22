# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.4.0

### Replace `ASPEC::Methods.assert_error` and `ASPEC::Methods.assert_success`

The `ASPEC::Methods.assert_error` and `ASPEC::Methods.assert_success` methods have been removed in favor new methods that more clearly show intent:

* If using `.assert_error` _without_ the `codegen` argument (the default), use `.assert_compile_time_error` instead
* If using `.assert_error` _with_ `codegen: true` argument, use `.assert_runtime_error` instead
* If using `.assert_success` _without_ the `codegen` argument (the default), use `.assert_compiles` instead
* If using `.assert_success` _with_ `codegen: true` argument, use `.assert_executes` instead

## Upgrade to 0.3.10

### `ASPEC::TestCase#initialize` must be argless

Previously it was possible to define an `#initialize` method that accepted arguments/a block.
This was unintended and now results in a compile time error.
