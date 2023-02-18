# Changelog

## [0.3.2] - 2023-02-18

### Changed

- Update some links in preparation for Athena Framework `0.18.0` ([#261](https://github.com/athena-framework/athena/pull/261)) (George Dietrich)

### Fixed

- Fix formatting issue in Crystal `1.8-dev` ([#258](https://github.com/athena-framework/athena/pull/258)) (George Dietrich)

## [0.3.1] - 2023-02-04

### Added

- Add better integration between `Athena::Console` and `Athena::DependencyInjection` ([#259](https://github.com/athena-framework/athena/pull/259)) (George Dietrich)

## [0.3.0] - 2023-01-07

### Changed

- **Breaking:** deprecate command default name/description class variables in favor of the new `ACONA::AsCommand` annotation ([#214](https://github.com/athena-framework/athena/pull/214)) (George Dietrich)
- **Breaking:** refactor `ACON::Command#application=` to no longer have a `nil` default value ([#217](https://github.com/athena-framework/athena/pull/217)) (George Dietrich)
- **Breaking:** refactor `ACON::Command#process_title=` no longer accept `nil` ([#217](https://github.com/athena-framework/athena/pull/217)) (George Dietrich)
- **Breaking:** rename `ACON::Command#process_title=` to `ACON::Command#process_title` ([#217](https://github.com/athena-framework/athena/pull/217)) (George Dietrich)

### Added

- **Breaking:** add `#table` method to `ACON::Style::Interface` ([#220](https://github.com/athena-framework/athena/pull/220)) (George Dietrich)
- Add `ACONA::AsCommand` annotation to configure a command's name, description, aliases, and if it should be hidden ([#214](https://github.com/athena-framework/athena/pull/214)) (George Dietrich)
- Add support for generating tables ([#220](https://github.com/athena-framework/athena/pull/220)) (George Dietrich)

### Fixed

- Fix issue with using `ACON::Formatter::Output#format_and_wrap` with `nil` input and an edge case when wrapping a string with a space at the limit ([#220](https://github.com/athena-framework/athena/pull/220)) (George Dietrich)
- Fix `ACON::Formatter::NullStyle#*_option` method using incorrect `ACON::Formatter::Mode` type restriction ([#220](https://github.com/athena-framework/athena/pull/220)) (George Dietrich)
- Fix some flakiness when testing commands with input ([#224](https://github.com/athena-framework/athena/pull/224)) (George Dietrich)
- Fix compiler error when trying to use `ACON::Style::Athena#error_style` ([#240](https://github.com/athena-framework/athena/pull/240)) (George Dietrich)

## [0.2.1] - 2022-09-05

### Changed

- **Breaking:** ensure parameter names defined on interfaces match the implementation ([#188](https://github.com/athena-framework/athena/pull/188)) (George Dietrich)

### Added

- Add an `ACON::Input::Interface` based on a command line string ([#186](https://github.com/athena-framework/athena/pull/186), [#187](https://github.com/athena-framework/athena/pull/187)) (George Dietrich)

## [0.2.0] - 2022-05-14

_First release a part of the monorepo._

### Changed

- **Breaking:** remove `ACON::Formatter::Mode` in favor of `Colorize::Mode`. Breaking only if not using symbol autocasting. ([#170](https://github.com/athena-framework/athena/pull/170)) (George Dietrich)
- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

### Added

- Add `VERSION` constant to `Athena::Console` namespace ([#166](https://github.com/athena-framework/athena/pull/166)) (George Dietrich)
- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)

### Fixed

- Disallow multi char option shortcuts made up of diff chars ([#164](https://github.com/athena-framework/athena/pull/164)) (George Dietrich)

## [0.1.1] - 2021-12-01

### Fixed

- **Breaking:** fix typo in parameter name of `ACON::Command#option` method ([#3](https://github.com/athena-framework/console/pull/3)) (George Dietrich)
- Fix recursive struct error ([#4](https://github.com/athena-framework/console/pull/4)) (George Dietrich)

## [0.1.0] - 2021-10-30

_Initial release._

[0.3.2]: https://github.com/athena-framework/console/releases/tag/v0.3.2
[0.3.1]: https://github.com/athena-framework/console/releases/tag/v0.3.1
[0.3.0]: https://github.com/athena-framework/console/releases/tag/v0.3.0
[0.2.1]: https://github.com/athena-framework/console/releases/tag/v0.2.1
[0.2.0]: https://github.com/athena-framework/console/releases/tag/v0.2.0
[0.1.1]: https://github.com/athena-framework/console/releases/tag/v0.1.1
[0.1.0]: https://github.com/athena-framework/console/releases/tag/v0.1.0
