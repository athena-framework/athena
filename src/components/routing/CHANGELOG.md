# Changelog

## [0.1.9] - 2024-04-09

### Changed

- Integrate website into monorepo ([#365](https://github.com/athena-framework/athena/pull/365)) (George Dietrich)

### Added

- Add kwargs overload to `ART::Generator::Interface#generate` ([#375](https://github.com/athena-framework/athena/pull/375)) (George Dietrich)

### Fixed

- Fix compatibility with PCRE2 10.43 ([#362](https://github.com/athena-framework/athena/pull/362)) (George Dietrich)
- Fix error when PCRE2 JIT mode is unavailable ([#381](https://github.com/athena-framework/athena/pull/381)) (George Dietrich)

## [0.1.8] - 2023-10-09

### Added

- Internal support for redirecting within an `ART::Matcher::*` ([#307](https://github.com/athena-framework/athena/pull/307)) (George Dietrich)

## [0.1.7] - 2023-05-29

### Changed

- **Breaking:** Update minimum `crystal` version to `~> 1.8.0`. Drop support for `PCRE1`. ([#281](https://github.com/athena-framework/athena/pull/281)) (George Dietrich)

## [0.1.6] - 2023-03-26

### Fixed

- Fix compatibility with Crystal `1.8.0-dev` ([#272](https://github.com/athena-framework/athena/pull/272)) (George Dietrich)

## [0.1.5] - 2023-02-18

### Changed

- Update some links in preparation for Athena Framework `0.18.0` ([#261](https://github.com/athena-framework/athena/pull/261)) (George Dietrich)

### Added

- Add additional `ART::Requirement` constants ([#257](https://github.com/athena-framework/athena/pull/257)) (George Dietrich)

### Fixed

- Fix formatting issue in Crystal `1.8-dev` ([#258](https://github.com/athena-framework/athena/pull/258)) (George Dietrich)

## [0.1.4] - 2023-01-07

### Changed

- Change route compilation to be eager ([#207](https://github.com/athena-framework/athena/pull/207)) (George Dietrich)

### Added

- Add ability to bubble up exceptions from `ART::RoutingHandler` ([#206](https://github.com/athena-framework/athena/pull/206)) (George Dietrich)
- Add `ART::Matcher::TraceableURLMatcher` to help with debugging route matches ([#224](https://github.com/athena-framework/athena/pull/224)) (George Dietrich)
- Add `ART::Route#has_scheme?` ([#224](https://github.com/athena-framework/athena/pull/224)) (George Dietrich)

## [0.1.3] - 2022-09-05

### Changed

- **Breaking:** ensure parameter names defined on interfaces match the implementation ([#188](https://github.com/athena-framework/athena/pull/188)) (George Dietrich)

### Added

- Add an `HTTP::Handler` to add basic routing support to a `HTTP::Server` ([#189](https://github.com/athena-framework/athena/pull/189)) (George Dietrich)

### Fixed

- Fixed slash characters being double escaped in generated URL query params ([#180](https://github.com/athena-framework/athena/pull/180)) (George Dietrich)

## [0.1.2] - 2022-05-14

### Changed

- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

### Added

- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)
- Add common route requirement constants to the [ART::Requirement](https://athenaframework.org/Routing/Requirement/) namespace ([#173](https://github.com/athena-framework/athena/pull/173)) (George Dietrich)
- Add [ART::Requirement::Enum](https://athenaframework.org/Routing/Requirement/Enum/) to make creating [Enum](https://crystal-lang.org/api/Enum.html) based route requirements easier ([#173](https://github.com/athena-framework/athena/pull/173)) (George Dietrich)

## [0.1.1] - 2022-02-05

_First release a part of the monorepo._

### Fixed

- Fix erroneous mutating of matched route data ([#144](https://github.com/athena-framework/athena/pull/144)) (George Dietrich)

## [0.1.0] - 2022-01-10

_Initial release._

[0.1.9]: https://github.com/athena-framework/routing/releases/tag/v0.1.9
[0.1.8]: https://github.com/athena-framework/routing/releases/tag/v0.1.8
[0.1.7]: https://github.com/athena-framework/routing/releases/tag/v0.1.7
[0.1.6]: https://github.com/athena-framework/routing/releases/tag/v0.1.6
[0.1.5]: https://github.com/athena-framework/routing/releases/tag/v0.1.5
[0.1.4]: https://github.com/athena-framework/routing/releases/tag/v0.1.4
[0.1.3]: https://github.com/athena-framework/routing/releases/tag/v0.1.3
[0.1.2]: https://github.com/athena-framework/routing/releases/tag/v0.1.2
[0.1.1]: https://github.com/athena-framework/routing/releases/tag/v0.1.1
[0.1.0]: https://github.com/athena-framework/routing/releases/tag/v0.1.0
