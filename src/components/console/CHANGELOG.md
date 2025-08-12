# Changelog

## [0.4.1] - 2025-02-08

### Fixed

- Fix incorrectly aligned block ([#519]) (Zohir Tamda)

[0.4.1]: https://github.com/athena-framework/console/releases/tag/v0.4.1
[#519]: https://github.com/athena-framework/athena/pull/519

## [0.4.0] - 2025-01-26

### Changed

- **Breaking:** Normalize exception types ([#428]) (George Dietrich)

### Added

- **Breaking:** Add `ACON::Output::Verbosity::SILENT` verbosity level ([#489]) (George Dietrich)
- **Breaking:** Rename `ACON::Completion::Input#must_suggest_values_for?` to `#must_suggest_option_values_for?` ([#498]) (George Dietrich)
- Update minimum `crystal` version to `~> 1.13.0` ([#498]) (George Dietrich)
- Add `#assert_command_is_not_successful` spec expectation method ([#498]) (George Dietrich)
- Add support for [`FORCE_COLOR`](https://force-color.org/) and improve color support logic ([#488]) (George Dietrich)

### Fixed

- Fix unexpected completion value when given an array of options ([#498]) (George Dietrich)
- Fix error when trying to set `ACON::Helper::Table::Style#padding_char` ([#498]) (George Dietrich)

[0.4.0]: https://github.com/athena-framework/console/releases/tag/v0.4.0
[#428]: https://github.com/athena-framework/athena/pull/428
[#488]: https://github.com/athena-framework/athena/pull/488
[#489]: https://github.com/athena-framework/athena/pull/489
[#498]: https://github.com/athena-framework/athena/pull/498

## [0.3.6] - 2024-07-31

### Changed

- **Breaking:** `ACON::Application#getter` and constructor argument must now be a `String` instead of `SemanticVersion` ([#419]) (George Dietrich)
- Changed the default `ACON::Application` version to `UNKNOWN` from `0.1.0` ([#419]) (George Dietrich)
- List commands in a namespace when using it as the command name ([#427]) (George Dietrich)
- Use single quotes in text descriptor to quote values in the output ([#427]) (George Dietrich)

[0.3.6]: https://github.com/athena-framework/console/releases/tag/v0.3.6
[#419]: https://github.com/athena-framework/athena/pull/419
[#427]: https://github.com/athena-framework/athena/pull/427

## [0.3.5] - 2024-04-09

### Changed

- Update minimum `crystal` version to `~> 1.11.0` ([#270]) (George Dietrich)
- Integrate website into monorepo ([#365]) (George Dietrich)

### Added

- Support for Windows OS ([#270]) (George Dietrich)

### Fixed

- Fix incorrect column/width `ACON::Terminal` values on Windows ([#361]) (George Dietrich)

[0.3.5]: https://github.com/athena-framework/console/releases/tag/v0.3.5
[#270]: https://github.com/athena-framework/athena/pull/270
[#365]: https://github.com/athena-framework/athena/pull/365
[#361]: https://github.com/athena-framework/athena/pull/361

## [0.3.4] - 2023-10-10

### Added

- Add support for tab completion to the `bash` shell when binary is in the `bin/` directory and referenced with `./` ([#323]) (George Dietrich)

[0.3.4]: https://github.com/athena-framework/console/releases/tag/v0.3.4
[#323]: https://github.com/athena-framework/athena/pull/323

## [0.3.3] - 2023-10-09

### Changed

- Update minimum `crystal` version to `~> 1.8.0` ([#282]) (George Dietrich)

### Added

- **Breaking:** Add `ACON::Helper::ProgressBar` to enable rendering progress bars ([#304]) (George Dietrich)
- Add native shell tab completion support for `bash`, `zsh`, and `fish` for both built-in and custom commands ([#294], [#296], [#297], [#299]) (George Dietrich)
- Add `ACON::Helper::ProgressIndicator` to enable rendering spinners ([#314]) (George Dietrich)
- Add support for defining a max height for an `ACON::Output::Section` ([#303]) (George Dietrich)
- Add `ACON::Helper.format_time` to format a duration as a human readable string ([#304]) (George Dietrich)
- Add `#assert_command_is_successful` helper method to `ACON::Spec::CommandTester` and `ACON::Spec::ApplicationTester` ([#294]) (George Dietrich)

### Fixed

- Ensure long lines with URLs are not cut when wrapped ([#314]) (George Dietrich)
- Do not emit erroneous newline from `ACON::Style::Athena` when it's the first thing being written ([#314]) (George Dietrich)
- Fix misalignment when word wrapping a hyperlink ([#305]) (George Dietrich)
- Do not emit erroneous extra newlines from an `ACON::Output::Section` ([#303]) (George Dietrich)
- Fix misalignment within a vertical table with multi-line cell ([#300]) (George Dietrich)

[0.3.3]: https://github.com/athena-framework/console/releases/tag/v0.3.3
[#282]: https://github.com/athena-framework/athena/pull/282
[#294]: https://github.com/athena-framework/athena/pull/294
[#296]: https://github.com/athena-framework/athena/pull/296
[#297]: https://github.com/athena-framework/athena/pull/297
[#299]: https://github.com/athena-framework/athena/pull/299
[#300]: https://github.com/athena-framework/athena/pull/300
[#303]: https://github.com/athena-framework/athena/pull/303
[#304]: https://github.com/athena-framework/athena/pull/304
[#305]: https://github.com/athena-framework/athena/pull/305
[#314]: https://github.com/athena-framework/athena/pull/314

## [0.3.2] - 2023-02-18

### Changed

- Update some links in preparation for Athena Framework `0.18.0` ([#261]) (George Dietrich)

### Fixed

- Fix formatting issue in Crystal `1.8-dev` ([#258]) (George Dietrich)

[0.3.2]: https://github.com/athena-framework/console/releases/tag/v0.3.2
[#261]: https://github.com/athena-framework/athena/pull/261
[#258]: https://github.com/athena-framework/athena/pull/258

## [0.3.1] - 2023-02-04

### Added

- Add better integration between `Athena::Console` and `Athena::DependencyInjection` ([#259]) (George Dietrich)

[0.3.1]: https://github.com/athena-framework/console/releases/tag/v0.3.1
[#259]: https://github.com/athena-framework/athena/pull/259

## [0.3.0] - 2023-01-07

### Changed

- **Breaking:** deprecate command default name/description class variables in favor of the new `ACONA::AsCommand` annotation ([#214]) (George Dietrich)
- **Breaking:** refactor `ACON::Command#application=` to no longer have a `nil` default value ([#217]) (George Dietrich)
- **Breaking:** refactor `ACON::Command#process_title=` no longer accept `nil` ([#217]) (George Dietrich)
- **Breaking:** rename `ACON::Command#process_title=` to `ACON::Command#process_title` ([#217]) (George Dietrich)

### Added

- **Breaking:** add `#table` method to `ACON::Style::Interface` ([#220]) (George Dietrich)
- Add `ACONA::AsCommand` annotation to configure a command's name, description, aliases, and if it should be hidden ([#214]) (George Dietrich)
- Add support for generating tables ([#220]) (George Dietrich)

### Fixed

- Fix issue with using `ACON::Formatter::Output#format_and_wrap` with `nil` input and an edge case when wrapping a string with a space at the limit ([#220]) (George Dietrich)
- Fix `ACON::Formatter::NullStyle#*_option` method using incorrect `ACON::Formatter::Mode` type restriction ([#220]) (George Dietrich)
- Fix some flakiness when testing commands with input ([#224]) (George Dietrich)
- Fix compiler error when trying to use `ACON::Style::Athena#error_style` ([#240]) (George Dietrich)

[0.3.0]: https://github.com/athena-framework/console/releases/tag/v0.3.0
[#214]: https://github.com/athena-framework/athena/pull/214
[#217]: https://github.com/athena-framework/athena/pull/217
[#220]: https://github.com/athena-framework/athena/pull/220
[#224]: https://github.com/athena-framework/athena/pull/224
[#240]: https://github.com/athena-framework/athena/pull/240

## [0.2.1] - 2022-09-05

### Changed

- **Breaking:** ensure parameter names defined on interfaces match the implementation ([#188]) (George Dietrich)

### Added

- Add an `ACON::Input::Interface` based on a command line string ([#186], [#187]) (George Dietrich)

[0.2.1]: https://github.com/athena-framework/console/releases/tag/v0.2.1
[#186]: https://github.com/athena-framework/athena/pull/186
[#187]: https://github.com/athena-framework/athena/pull/187
[#188]: https://github.com/athena-framework/athena/pull/188

## [0.2.0] - 2022-05-14

_First release a part of the monorepo._

### Changed

- **Breaking:** remove `ACON::Formatter::Mode` in favor of `Colorize::Mode`. Breaking only if not using symbol autocasting. ([#170]) (George Dietrich)
- Update minimum `crystal` version to `~> 1.4.0` ([#169]) (George Dietrich)

### Added

- Add `VERSION` constant to `Athena::Console` namespace ([#166]) (George Dietrich)
- Add getting started documentation to API docs ([#172]) (George Dietrich)

### Fixed

- Disallow multi char option shortcuts made up of diff chars ([#164]) (George Dietrich)

[0.2.0]: https://github.com/athena-framework/console/releases/tag/v0.2.0
[#164]: https://github.com/athena-framework/athena/pull/164
[#166]: https://github.com/athena-framework/athena/pull/166
[#169]: https://github.com/athena-framework/athena/pull/169
[#170]: https://github.com/athena-framework/athena/pull/170
[#172]: https://github.com/athena-framework/athena/pull/172

## [0.1.1] - 2021-12-01

### Fixed

- **Breaking:** fix typo in parameter name of `ACON::Command#option` method ([#3]) (George Dietrich)
- Fix recursive struct error ([#4]) (George Dietrich)

[0.1.1]: https://github.com/athena-framework/console/releases/tag/v0.1.1
[#3]: https://github.com/athena-framework/console/pull/3
[#4]: https://github.com/athena-framework/console/pull/4

## [0.1.0] - 2021-10-30

_Initial release._

[0.1.0]: https://github.com/athena-framework/console/releases/tag/v0.1.0
