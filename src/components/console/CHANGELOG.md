# Changelog

## [0.2.0] - 2022-05-14

_First release a part of the monorepo._

### Added

- Add `VERSION` constant to `Athena::Console` namespace ([#166](https://github.com/athena-framework/athena/pull/166)) (George Dietrich)
- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)

### Changed

- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)
- **Breaking:** remove `ACON::Formatter::Mode` in favor of `Colorize::Mode` ([#170](https://github.com/athena-framework/athena/pull/170)) (George Dietrich). Breaking only if not using symbol autocasting.

### Fixed

- Disallow multi char option shortcuts made up of diff chars ([#164](https://github.com/athena-framework/athena/pull/164)) (George Dietrich)

## [0.1.1] - 2021-12-01

### Fixed

- Fix recursive struct error ([#4](https://github.com/athena-framework/console/pull/4)) (George Dietrich)
- **Breaking:** fix typo in parameter name of `ACON::Command#option` method ([#3](https://github.com/athena-framework/console/pull/3)) (George Dietrich)

## [0.1.0] - 2021-10-30

_Initial release._

[0.2.0]: https://github.com/athena-framework/console/releases/tag/v0.2.0
[0.1.1]: https://github.com/athena-framework/console/releases/tag/v0.1.1
[0.1.0]: https://github.com/athena-framework/console/releases/tag/v0.1.0
