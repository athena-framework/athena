# Changelog

## [0.2.0] - 2026-10-18

### Changed

- **Breaking:** The `jwt` shard is now an optional dependency ([#760]) (George Dietrich) <!-- blacksmoke16 -->
- **Breaking:** The Mercure component and bundle now default to Mercure protocol 1.0 ([#762]) (George Dietrich) <!-- blacksmoke16 -->
- **Breaking:** `AMC::TokenFactory::Interface#create`, `AMC::TokenProvider::Factory` and `AMC::Authorization` cookies are now built from `AMC::Grants` ([#762]) (George Dietrich) <!-- blacksmoke16 -->

### Added

- Add `AMC::TokenFactory::DefaultClaims` to add default claims to every token a factory creates ([#762]) (George Dietrich) <!-- blacksmoke16 -->
- Add the bundle's publisher/subscriber, jwt.provider/jwt.factory, claims, protocol_version and cookie_name hub options ([#762]) (George Dietrich) <!-- blacksmoke16 -->

### Fixed

- Fix non-default hubs of the Mercure bundle being removed from the hub registry, and fix only the last hub's named token aliases being registered ([#762]) (George Dietrich) <!-- blacksmoke16 -->
- Fix overriding the mercure claim of an `AMC::TokenFactory::JWT` token emitting a duplicate claim ([#762]) (George Dietrich) <!-- blacksmoke16 -->

[0.2.0]: https://github.com/athena-framework/mercure/releases/tag/v0.2.0
[#760]: https://github.com/athena-framework/athena/pull/760
[#762]: https://github.com/athena-framework/athena/pull/762

## [0.1.0] - 2026-04-19

_Initial release._

[0.1.0]: https://github.com/athena-framework/mercure/releases/tag/v0.1.0
