# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.2.0

### Dropped `ACLK::Interface#sleep(Number)` overload

https://github.com/crystal-lang/crystal/pull/14962 deprecated `::sleep(Number)` in the stdlib.
The clock component follows suite, with the same migration path.
Instead of `.sleep 5` do `.sleep 5.seconds`.
