# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.2.0

### Remove `ACLK::Monotonic`

`Time.monotonic` has been [deprecated](https://github.com/crystal-lang/rfcs/pull/15) in Crystal stdlib.
The new `Time.instant` API doesn't, for good reason, doesn't have any overlap with `Time`, thus making it somewhat incompatible with `ACLK::Interface`.
Use cases that require measuring time should likely just use `Time.instant` directly.

### Dropped `ACLK::Interface#sleep(Number)` overload

`::sleep(Number)` has been [deprecated](https://github.com/crystal-lang/crystal/pull/14962) in Crystal stdlib.
The clock component follows suite, with the same migration path.
Instead of `.sleep 5` do `.sleep 5.seconds`.
