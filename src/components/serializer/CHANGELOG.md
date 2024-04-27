# Changelog

## [0.3.6] - 2024-04-27

### Fixed

- Fix misnamed modules being defined in incorrect namespace ([#402](https://github.com/athena-framework/athena/pull/402)) (George Dietrich)

## [0.3.5] - 2024-04-09

### Changed

- Change `Config` dependency to `DependencyInjection` for the custom annotation feature ([#392](https://github.com/athena-framework/athena/pull/392)) (George Dietrich)
- Integrate website into monorepo ([#365](https://github.com/athena-framework/athena/pull/365)) (George Dietrich)

## [0.3.4] - 2023-10-09

_Administrative release, no functional changes_

## [0.3.3] - 2023-02-18

### Changed

- Update some links in preparation for Athena Framework `0.18.0` ([#261](https://github.com/athena-framework/athena/pull/261)) (George Dietrich)

## [0.3.2] - 2023-01-07

### Fixed

- Fix deserializing `JSON::Any` and `YAML::Any` ([#215](https://github.com/athena-framework/athena/pull/215)) (George Dietrich)

## [0.3.1] - 2022-09-05

### Changed

- **Breaking:** ensure parameter names defined on interfaces match the implementation ([#188](https://github.com/athena-framework/athena/pull/188)) (George Dietrich)

## [0.3.0] - 2022-05-14

_First release a part of the monorepo._

### Added

- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)

### Changed

- **Breaking:** change serialization of [Enums](https://crystal-lang.org/api/Enum.html) to underscored strings by default ([#173](https://github.com/athena-framework/athena/pull/173)) (George Dietrich)
- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

### Fixed

- Fix compiler error when trying to deserialize a `Hash` ([#165](https://github.com/athena-framework/athena/pull/165)) (George Dietrich)

## [0.2.10] - 2021-11-12

### Fixed

- Fix issue with empty YAML input ([#22](https://github.com/athena-framework/serializer/pull/22)) (George Dietrich)

## [0.2.9] - 2021-10-30

### Added

- Add `VERSION` constant to `Athena::Serializer` namespace ([#20](https://github.com/athena-framework/serializer/pull/20)) (George Dietrich)

### Fixed

- Fix broken type link ([#19](https://github.com/athena-framework/serializer/pull/19)) (George Dietrich)

## [0.2.8] - 2021-05-17

### Fixed

- Fixes incorrect `nil` check in macro logic ([#17](https://github.com/athena-framework/serializer/pull/17)) (George Dietrich)

## [0.2.7] - 2021-04-09

### Added

- Add some more specialized exception types ([#16](https://github.com/athena-framework/serializer/pull/16)) (George Dietrich)

## [0.2.6] - 2021-03-16

### Added

- Expose a setter for `ASR::Context#version=` ([#15](https://github.com/athena-framework/serializer/pull/15)) (George Dietrich)

### Changed

- Change `athena-framework/config` version constraint to `>= 2.0.0` ([#15](https://github.com/athena-framework/serializer/pull/15)) (George Dietrich)

## [0.2.5] - 2021-01-29

### Changed

- Migrate documentation to [MkDocs](https://mkdocstrings.github.io/crystal/) ([#14](https://github.com/athena-framework/serializer/pull/14)) (George Dietrich)

## [0.2.4] - 2021-01-29

### Changed

- Bump min `athena-framework/config` version to `~> 2.0.0` ([#13](https://github.com/athena-framework/serializer/pull/13)) (George Dietrich)

## [0.2.3] - 2021-01-20

### Fixed

- Fix since/until and group annotations not working for virtual properties ([#12](https://github.com/athena-framework/serializer/pull/12)) (George Dietrich)

## [0.2.2] - 2020-12-03

### Changed

- Update `crystal` version to allow version greater than `1.0.0` ([#11](https://github.com/athena-framework/serializer/pull/11)) (George Dietrich)

## [0.2.1] - 2020-11-08

### Added

- Add deserialization support to `ASRA::Name` ([#9](https://github.com/athena-framework/serializer/pull/9)) (Joakim Repomaa)

## [0.2.0] - 2020-07-08

### Added

- Add dependency on `athena-framework/config` ([#8](https://github.com/athena-framework/serializer/pull/8)) (George Dietrich)
- Add ability to use custom annotations within [exclusion strategies](https://athenaframework.org/Serializer/ExclusionStrategies/ExclusionStrategyInterface/#Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface--annotation-configurations) ([#8](https://github.com/athena-framework/serializer/pull/8)) (George Dietrich)
- Add [ASR::Context#direction](https://athenaframework.org/Serializer/Context/#Athena::Serializer::Context#direction) to represent which direction the context object represents ([#8](https://github.com/athena-framework/serializer/pull/8)) (George Dietrich)

## [0.1.3] - 2020-07-08

### Fixed

- Fix overflow error when deserializing `Int64` values ([#7](https://github.com/athena-framework/serializer/pull/7)) (George Dietrich)

## [0.1.2] - 2020-07-05

### Added

- Add improved documentation to various types ([#6](https://github.com/athena-framework/serializer/pull/6)) (George Dietrich)

## [0.1.1] - 2020-06-27

### Added

- Add [naming strategies](https://athenaframework.org/Serializer/Annotations/Name/#Athena::Serializer::Annotations::Name--naming-strategies) to `ASRA::Name` ([#5](https://github.com/athena-framework/serializer/pull/5)) (George Dietrich)

## [0.1.0] - 2020-06-23

_Initial release._

[0.3.6]: https://github.com/athena-framework/serializer/releases/tag/v0.3.6
[0.3.5]: https://github.com/athena-framework/serializer/releases/tag/v0.3.5
[0.3.4]: https://github.com/athena-framework/serializer/releases/tag/v0.3.4
[0.3.3]: https://github.com/athena-framework/serializer/releases/tag/v0.3.3
[0.3.2]: https://github.com/athena-framework/serializer/releases/tag/v0.3.2
[0.3.1]: https://github.com/athena-framework/serializer/releases/tag/v0.3.1
[0.3.0]: https://github.com/athena-framework/serializer/releases/tag/v0.3.0
[0.2.10]: https://github.com/athena-framework/serializer/releases/tag/v0.2.10
[0.2.9]: https://github.com/athena-framework/serializer/releases/tag/v0.2.9
[0.2.8]: https://github.com/athena-framework/serializer/releases/tag/v0.2.8
[0.2.7]: https://github.com/athena-framework/serializer/releases/tag/v0.2.7
[0.2.6]: https://github.com/athena-framework/serializer/releases/tag/v0.2.6
[0.2.5]: https://github.com/athena-framework/serializer/releases/tag/v0.2.5
[0.2.4]: https://github.com/athena-framework/serializer/releases/tag/v0.2.4
[0.2.3]: https://github.com/athena-framework/serializer/releases/tag/v0.2.3
[0.2.2]: https://github.com/athena-framework/serializer/releases/tag/v0.2.2
[0.2.1]: https://github.com/athena-framework/serializer/releases/tag/v0.2.1
[0.2.0]: https://github.com/athena-framework/serializer/releases/tag/v0.2.0
[0.1.3]: https://github.com/athena-framework/serializer/releases/tag/v0.1.3
[0.1.2]: https://github.com/athena-framework/serializer/releases/tag/v0.1.2
[0.1.1]: https://github.com/athena-framework/serializer/releases/tag/v0.1.1
[0.1.0]: https://github.com/athena-framework/serializer/releases/tag/v0.1.0
