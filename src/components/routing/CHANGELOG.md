# Changelog

## [0.1.3] - 2022-09-05

### Added

- Add an `HTTP::Handler` to add basic routing support to a `HTTP::Server` ([#189](https://github.com/athena-framework/athena/pull/189)) (George Dietrich)

### Changed

- **Breaking:** ensure parameter names defined on interfaces match the implementation ([#188](https://github.com/athena-framework/athena/pull/188)) (George Dietrich)

### Fixed

- Fixed slash characters being double escaped in generated URL query params ([#180](https://github.com/athena-framework/athena/pull/180)) (George Dietrich)

## [0.1.2] - 2022-05-14

### Added

- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)
- Add common route requirement constants to the [ART::Requirement](https://athenaframework.org/Routing/Requirement/) namespace ([#173](https://github.com/athena-framework/athena/pull/173)) (George Dietrich)
- Add [ART::Requirement::Enum](https://athenaframework.org/Routing/Requirement/Enum/) to make creating [Enum](https://crystal-lang.org/api/Enum.html) based route requirements easier ([#173](https://github.com/athena-framework/athena/pull/173)) (George Dietrich)

### Changed

- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

## [0.1.1] - 2022-02-05

_First release a part of the monorepo._

### Fixed

- Fix erroneous mutating of matched route data ([#144](https://github.com/athena-framework/athena/pull/144)) (George Dietrich)

## [0.1.0] - 2022-01-10

_Initial release._

[0.1.3]: https://github.com/athena-framework/routing/releases/tag/v0.1.3
[0.1.2]: https://github.com/athena-framework/routing/releases/tag/v0.1.2
[0.1.1]: https://github.com/athena-framework/routing/releases/tag/v0.1.1
[0.1.0]: https://github.com/athena-framework/routing/releases/tag/v0.1.0
