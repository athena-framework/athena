# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.3.10

### `ASPEC::TestCase#initialize` must be argless

Previously it was possible to define an `#initialize` method that accepted arguments/a block.
This was unintended and now results in a compile time error.
