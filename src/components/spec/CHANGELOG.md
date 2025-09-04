# Changelog

## [0.4.0] - 2025-09-04

### Added

- Add support for generating macro code coverage reports for `.assert_error` and `.assert_compiles` methods ([#551]) (George Dietrich) <!-- blacksmoke16 -->

### Removed

- Remove `codegen` parameter from `ASPEC::Methods.assert_error` and `ASPEC::Methods.assert_success` ([#551]) (George Dietrich) <!-- blacksmoke16 -->
- Remove `ASPEC::Methods.assert_error` in favor of `ASPEC::Methods.assert_compile_time_error` and `ASPEC::Methods.assert_runtime_error` ([#551]) (George Dietrich) <!-- blacksmoke16 -->
- Remove `ASPEC::Methods.assert_success` in favor of `ASPEC::Methods.assert_compiles` and `ASPEC::Methods.assert_executes` ([#551]) (George Dietrich) <!-- blacksmoke16 -->

[0.4.0]: https://github.com/athena-framework/spec/releases/tag/v0.4.0
[#551]: https://github.com/athena-framework/athena/pull/551

## [0.3.11] - 2025-05-19

### Fixed

- Fix duplicate test case runs with abstract generic parent test case ([#538]) (George Dietrich)

[0.3.11]: https://github.com/athena-framework/spec/releases/tag/v0.3.11
[#538]: https://github.com/athena-framework/athena/pull/538

## [0.3.10] - 2025-02-08

### Changed

- **Breaking:** prevent defining `ASPEC::TestCase#initialize` methods that accepts arguments/blocks ([#516]) (George Dietrich)

[0.3.10]: https://github.com/athena-framework/spec/releases/tag/v0.3.10
[#516]: https://github.com/athena-framework/athena/pull/516

## [0.3.9] - 2025-01-26

_Administrative release, no functional changes_

[0.3.9]: https://github.com/athena-framework/spec/releases/tag/v0.3.9

## [0.3.8] - 2024-07-31

### Added

- Add support for using the `CRYSTAL` ENV var to customize binary used for `ASPEC::Methods.assert_error` and `ASPEC::Methods.assert_success` ([#424]) (George Dietrich)

[0.3.8]: https://github.com/athena-framework/spec/releases/tag/v0.3.8
[#424]: https://github.com/athena-framework/athena/pull/424

## [0.3.7] - 2024-04-09

### Changed

- Integrate website into monorepo ([#365]) (George Dietrich)

[0.3.7]: https://github.com/athena-framework/spec/releases/tag/v0.3.7
[#365]: https://github.com/athena-framework/athena/pull/365

## [0.3.6] - 2023-10-09

_Administrative release, no functional changes_

[0.3.6]: https://github.com/athena-framework/spec/releases/tag/v0.3.6

## [0.3.5] - 2023-04-26

### Fixed

- Ensure `#before_all` runs exactly once, and before `#initialize` ([#285]) (George Dietrich)

[0.3.5]: https://github.com/athena-framework/spec/releases/tag/v0.3.5
[#285]: https://github.com/athena-framework/athena/pull/285

## [0.3.4] - 2023-03-19

### Fixed

- Fix exceptions not being counted as errors when raised within the `initialize` method of a test case ([#276]) (George Dietrich)
- Fix a documentation typo in the `TestWith` example ([#269]) (George Dietrich)

[0.3.4]: https://github.com/athena-framework/spec/releases/tag/v0.3.4
[#269]: https://github.com/athena-framework/athena/pull/269
[#276]: https://github.com/athena-framework/athena/pull/276

## [0.3.3] - 2023-02-18

### Changed

- Update some links in preparation for Athena Framework `0.18.0` ([#261]) (George Dietrich)

[0.3.3]: https://github.com/athena-framework/spec/releases/tag/v0.3.3
[#261]: https://github.com/athena-framework/athena/pull/261

## [0.3.2] - 2023-01-16

### Added

- Add `ASPEC::TestCase::TestWith` that works similar to the `ASPEC::TestCase::DataProvider` but without needing to create a dedicated method ([#254]) (George Dietrich)

[0.3.2]: https://github.com/athena-framework/spec/releases/tag/v0.3.2
[#254]: https://github.com/athena-framework/athena/pull/254

## [0.3.1] - 2023-01-07

### Changed

- Update the docs to clarify the component needs to be manually installed ([#247]) (George Dietrich)

### Added

- Add support for *codegen* for the `ASPEC.assert_error` and `ASPEC.assert_success` methods ([#219]) (George Dietrich)
- Add ability to skip running all examples within a test case via the `ASPEC::TestCase::Skip` annotation ([#248]) (George Dietrich)

[0.3.1]: https://github.com/athena-framework/spec/releases/tag/v0.3.1
[#219]: https://github.com/athena-framework/athena/pull/219
[#247]: https://github.com/athena-framework/athena/pull/247
[#248]: https://github.com/athena-framework/athena/pull/248

## [0.3.0] - 2022-05-14

_First release a part of the monorepo._

### Changed

- **Breaking:** change the `assert_error` to no longer be file based. Code should now be provided as a HEREDOC argument to the method ([#173]) (George Dietrich)
- Update minimum `crystal` version to `~> 1.4.0` ([#169]) (George Dietrich)

### Added

- Add `VERSION` constant to `Athena::Spec` namespace ([#166]) (George Dietrich)
- Add getting started documentation to API docs ([#172]) (George Dietrich)
- Add [ASPEC::Methods.assert_success](https://athenaframework.org/Spec/Methods/#Athena::Spec::Methods#assert_success(code,*,line,file)) ([#173]) (George Dietrich)

[0.3.0]: https://github.com/athena-framework/spec/releases/tag/v0.3.0
[#166]: https://github.com/athena-framework/athena/pull/166
[#169]: https://github.com/athena-framework/athena/pull/169
[#172]: https://github.com/athena-framework/athena/pull/172
[#173]: https://github.com/athena-framework/athena/pull/173

## [0.2.6] - 2021-11-03

### Fixed

- Fix `test` helper macro generating invalid method names by replacing all non alphanumeric chars with `_`  ([#12]) (George Dietrich)

[0.2.6]: https://github.com/athena-framework/spec/releases/tag/v0.2.6
[#12]: https://github.com/athena-framework/spec/pull/12

## [0.2.5] - 2021-11-03

### Fixed

- Fix `test` helper macro not actually calling `yield`  ([#11]) (George Dietrich)

[0.2.5]: https://github.com/athena-framework/spec/releases/tag/v0.2.5
[#11]: https://github.com/athena-framework/spec/pull/11

## [0.2.4] - 2021-01-29

### Changed

- Finish migration to [MkDocs](https://mkdocstrings.github.io/crystal/) ([#9]) (George Dietrich)

[0.2.4]: https://github.com/athena-framework/spec/releases/tag/v0.2.4
[#9]: https://github.com/athena-framework/spec/pull/9

## [0.2.3] - 2020-12-03

### Changed

- Update `crystal` version to allow version greater than `1.0.0` ([#7]) (George Dietrich)

[0.2.3]: https://github.com/athena-framework/spec/releases/tag/v0.2.3
[#7]: https://github.com/athena-framework/spec/pull/7

## [0.2.2] - 2020-10-02

### Added

- Add support for data providers defined in parent types ([#6]) (George Dietrich)

[0.2.2]: https://github.com/athena-framework/spec/releases/tag/v0.2.2
[#6]: https://github.com/athena-framework/spec/pull/6

## [0.2.1] - 2020-09-25

### Changed

- Changed data provider generated `it` blocks have proper file names and line numbers ([#4]) (George Dietrich)

[0.2.1]: https://github.com/athena-framework/spec/releases/tag/v0.2.1
[#4]: https://github.com/athena-framework/spec/pull/4

## [0.2.0] - 2020-08-08

### Changed

- **Breaking:** require [data providers](https://athenaframework.org/Spec/TestCase/DataProvider/) methods to declare a return type of `Hash`, `NamedTuple`, `Tuple`, or `Array` ([#3]) (George Dietrich)
- Changed data provider generated `it` blocks to include the key/index ([#2]) (George Dietrich)

[0.2.0]: https://github.com/athena-framework/spec/releases/tag/v0.2.0
[#2]: https://github.com/athena-framework/spec/pull/2
[#3]: https://github.com/athena-framework/spec/pull/3

## [0.1.0] - 2020-08-06

_Initial release._

[0.1.0]: https://github.com/athena-framework/spec/releases/tag/v0.1.0
