# Changelog

## [0.4.3] - 2025-02-08

### Changed

- **Breaking:** prevent auto registering of already registered services ([#520](https://github.com/athena-framework/athena/pull/520)) (George Dietrich)

### Fixed

- Ensure all array values have proper `#of` type ([#508](https://github.com/athena-framework/athena/pull/508)) (George Dietrich)

## [0.4.2] - 2025-01-26

_Administrative release, no functional changes_

## [0.4.1] - 2024-07-31

### Changed

- **Breaking:** single implementation aliases are now explicit ([#408](https://github.com/athena-framework/athena/pull/408)) (George Dietrich)

### Fixed

- Fix default/nil values related to `object_of` and `array_of` being unavailable in bundle extensions ([#432](https://github.com/athena-framework/athena/pull/432)) (George Dietrich)

## [0.4.0] - 2024-04-09

### Changed

- **Breaking:** remove `Clock`, `Console`, and `EventDispatcher` built-in integrations ([#337](https://github.com/athena-framework/athena/pull/337)) (George Dietrich)
- **Breaking:** major internal refactor ([#337](https://github.com/athena-framework/athena/pull/337), [#378](https://github.com/athena-framework/athena/pull/378)) (George Dietrich)
- **Breaking:** replace `ADI.auto_configure` with [ADI::Autoconfigure](https://athenaframework.org/DependencyInjection/Autoconfigure/) ([#387](https://github.com/athena-framework/athena/pull/387)) (George Dietrich)
- **Breaking:** replace `alias` `ADI::Register` field with [ADI::AsAlias](https://athenaframework.org/DependencyInjection/AsAlias/) ([#389](https://github.com/athena-framework/athena/pull/389)) (George Dietrich)
- Integrate website into monorepo ([#365](https://github.com/athena-framework/athena/pull/365)) (George Dietrich)

### Added

- Add ability to easily extend/customize the container ([#337](https://github.com/athena-framework/athena/pull/337), [#348](https://github.com/athena-framework/athena/pull/348), [#371](https://github.com/athena-framework/athena/pull/371), [#372](https://github.com/athena-framework/athena/pull/372), [#373](https://github.com/athena-framework/athena/pull/373), [#374](https://github.com/athena-framework/athena/pull/374), [#377](https://github.com/athena-framework/athena/pull/377), [#379](https://github.com/athena-framework/athena/pull/379), [#382](https://github.com/athena-framework/athena/pull/382), [#383](https://github.com/athena-framework/athena/pull/383)) (George Dietrich)
- Add ability to define method calls that should be made during service instantiation ([#384](https://github.com/athena-framework/athena/pull/384)) (George Dietrich)
- Add new [ADI::AutoconfigureTag](https://athenaframework.org/DependencyInjection/AutoconfigureTag/) and [ADI::TaggedIterator](https://athenaframework.org/DependencyInjection/TaggedIterator/) to make working with tagged services easier ([#387](https://github.com/athena-framework/athena/pull/387)) (George Dietrich)
- Add `ADI.configuration_annotation` to `Athena::DependencyInjection` from `Athena::Config` ([#392](https://github.com/athena-framework/athena/pull/392)) (George Dietrich)

## [0.3.8] - 2023-12-16

### Fixed

- Avoid depending directly on Crystal macro types ([#335](https://github.com/athena-framework/athena/pull/335)) (George Dietrich)

## [0.3.7] - 2023-10-09

### Added

- Add integration between `Athena::DependencyInjection` and the `Athena::Clock` component ([#318](https://github.com/athena-framework/athena/pull/318)) (George Dietrich)

## [0.3.6] - 2023-02-18

### Changed

- Update some links in preparation for Athena Framework `0.18.0` ([#261](https://github.com/athena-framework/athena/pull/261)) (George Dietrich)

## [0.3.5] - 2023-02-04

### Added

- Add better integration between `Athena::DependencyInjection` and the `Athena::Console` and `Athena::EventDispatcher` components ([#259](https://github.com/athena-framework/athena/pull/259)) (George Dietrich)

## [0.3.4] - 2023-01-07

### Changed

- Refactor various internal logic (George Dietrich)

## [0.3.3] - 2022-05-14

_First release a part of the monorepo._

### Changed

- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

### Added

- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)

## [0.3.2] - 2021-10-30

### Changed

- Unused services are now excluded from the container ([#30](https://github.com/athena-framework/dependency-injection/pull/30)) (George Dietrich)

## [0.3.1] - 2021-03-28

### Fixed

- Fix error with untyped parameters with default values injecting ([#28](https://github.com/athena-framework/dependency-injection/pull/28)) (George Dietrich)

## [0.3.0] - 2021-03-20

### Added

- Allow injecting [configuration](https://athenaframework.org/DependencyInjection/Register/#Athena::DependencyInjection::Register--configuration) into services ([#27](https://github.com/athena-framework/dependency-injection/pull/27)) (George Dietrich)

## [0.2.6] - 2021-03-15

### Added

- Allow using the `ADI::Inject` annotation on class methods to create [factories](https://athenaframework.org/DependencyInjection/Register/#Athena::DependencyInjection::Register--factories) ([#25](https://github.com/athena-framework/dependency-injection/pull/25)) (George Dietrich)

## [0.2.5] - 2021-01-30

### Changed

- Migrate documentation to [MkDocs](https://mkdocstrings.github.io/crystal/) ([#23](https://github.com/athena-framework/dependency-injection/pull/23), [#24](https://github.com/athena-framework/dependency-injection/pull/24)) (George Dietrich)

## [0.2.4] - 2021-01-29

### Added

- Add dependency on `athena-framework/config` ([#20](https://github.com/athena-framework/dependency-injection/pull/20)) (George Dietrich)
- Add support for injecting [parameters](https://athenaframework.org/architecture/config/#parameters) into a service ([#20](https://github.com/athena-framework/dependency-injection/pull/20)) (George Dietrich)
- Add support for [service proxies](https://athenaframework.org/DependencyInjection/Register/#Athena::DependencyInjection::Register--service-proxies) ([#21](https://github.com/athena-framework/dependency-injection/pull/21)) (George Dietrich)

### Removed

- Remove the `lazy` `ADI::Register` field. All services are lazy by default now ([#21](https://github.com/athena-framework/dependency-injection/pull/21)) (George Dietrich)

### Fixed

- Fix issue building documentation ([#22](https://github.com/athena-framework/dependency-injection/pull/22)) (George Dietrich)

## [0.2.3] - 2020-12-24

### Fixed

- Fix error when a parameter has a default value after an array parameter ([#19](https://github.com/athena-framework/dependency-injection/pull/19)) (George Dietrich)

## [0.2.2] - 2020-12-03

### Changed

- Update `crystal` version to allow version greater than `1.0.0` ([#18](https://github.com/athena-framework/dependency-injection/pull/18)) (George Dietrich)

## [0.2.1] - 2020-11-14

### Added

- Add a mock container instance to allow mocking services ([#15](https://github.com/athena-framework/dependency-injection/pull/15)) (George Dietrich)
- Add ability to customize the type of a service within the container ([#15](https://github.com/athena-framework/dependency-injection/pull/15)) (George Dietrich)
- Add support for [factory pattern](https://athenaframework.org/DependencyInjection/Register/#Athena::DependencyInjection::Register--factories) constructors ([#16](https://github.com/athena-framework/dependency-injection/pull/16)) (George Dietrich)

## [0.2.0] - 2020-06-09

_Major refactor of the component._

### Added

- Add concept of [aliasing services](https://athenaframework.org/DependencyInjection/Register/#Athena::DependencyInjection::Register--aliasing-services) ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- Add concept of [binding values](https://athenaframework.org/DependencyInjection/#Athena::DependencyInjection:bind(key,value)) ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- Add concept of [auto configuration](https://athenaframework.org/DependencyInjection/#Athena::DependencyInjection:auto_configure(type,options)) ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- Add [ADI::Inject](https://athenaframework.org/DependencyInjection/Inject/) annotation ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- Add support for [generic services](https://athenaframework.org/DependencyInjection/Register/#Athena::DependencyInjection::Register--generic-services) ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)

### Changed

- **Breaking:** manually provided arguments now need to be prefixed with a `_` ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- **Breaking:** service names are now based on the `FQN` of the type, downcase underscored by default ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- Updated [optional services](https://athenaframework.org/DependencyInjection/Register/#Athena::DependencyInjection::Register--optional-services) to now be based on the type/default value of the parameter ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- Service dependencies are now resolved automatically, removes need to manually provide them ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)

### Removed

- **Breaking:** remove the `ADI::Service` module ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- **Breaking:** remove the `ADI::Injectable` module ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- **Breaking:** remove the `@?` syntax ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)
- **Breaking:** remove the `#get`, `#has`, `#resolve`, `#tagged`, and `#tags` methods from `ADI::ServiceContainer` ([#10](https://github.com/athena-framework/dependency-injection/pull/10)) (George Dietrich)

## [0.1.3] - 2020-04-06

### Fixed

- Fix an edge case by checking includers via `<=` ([#7](https://github.com/athena-framework/dependency-injection/pull/7)) (George Dietrich)

## [0.1.2] - 2020-02-22

### Changed

- Change type resolution logic to operate at compile time instead of runtime ([#6](https://github.com/athena-framework/dependency-injection/pull/6)) (George Dietrich)

## [0.1.1] - 2020-02-06

### Added

- Add the ability to redefine services ([#4](https://github.com/athena-framework/dependency-injection/pull/4)) (George Dietrich)

## [0.1.0] - 2020-01-31

_Initial release._

[0.4.3]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.4.3
[0.4.2]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.4.2
[0.4.1]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.4.1
[0.4.0]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.4.0
[0.3.8]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.8
[0.3.7]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.7
[0.3.6]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.6
[0.3.5]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.5
[0.3.4]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.4
[0.3.3]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.3
[0.3.2]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.2
[0.3.1]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.1
[0.3.0]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.3.0
[0.2.6]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.2.6
[0.2.5]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.2.5
[0.2.4]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.2.4
[0.2.3]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.2.3
[0.2.2]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.2.2
[0.2.1]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.2.1
[0.2.0]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.2.0
[0.1.3]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.1.3
[0.1.2]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.1.2
[0.1.1]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.1.1
[0.1.0]: https://github.com/athena-framework/dependency-injection/releases/tag/v0.1.0
