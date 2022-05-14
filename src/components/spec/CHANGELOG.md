# Changelog

## [0.3.0] - 2022-05-14

_First release a part of the monorepo._

### Added

- Add `VERSION` constant to `Athena::Spec` namespace ([#166](https://github.com/athena-framework/athena/pull/166)) (George Dietrich)
- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)
- Add [ASPEC::Methods.assert_success](https://athenaframework.org/Spec/Methods/#Athena::Spec::Methods#assert_success(code,*,line,file)) ([#173](https://github.com/athena-framework/athena/pull/173)) (George Dietrich)

### Changed

- **Breaking:** change the `assert_error` to no longer be file based. Code should now be provided as a HEREDOC argument to the method ([#173](https://github.com/athena-framework/athena/pull/173)) (George Dietrich)
- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

## [0.2.6] - 2021-11-03

### Fixed

- Fix `test` helper macro generating invalid method names by replacing all non alphanumeric chars with `_`  ([#12](https://github.com/athena-framework/spec/pull/12)) (George Dietrich

## [0.2.5] - 2021-11-03

### Fixed

- Fix `test` helper macro not actually calling `yield`  ([#11](https://github.com/athena-framework/spec/pull/11)) (George Dietrich)

## [0.2.4] - 2021-01-29

### Changed

- Finish migration to [MkDocs](https://mkdocstrings.github.io/crystal/) ([#9](https://github.com/athena-framework/spec/pull/9)) (George Dietrich)

## [0.2.3] - 2020-12-03

### Changed

- Update `crystal` version to allow version greater than `1.0.0` ([#7](https://github.com/athena-framework/spec/pull/7)) (George Dietrich

## [0.2.2] - 2020-10-02

### Added

- Add support for data providers defined in parent types ([#6](https://github.com/athena-framework/spec/pull/6)) (George Dietrich)

## [0.2.1] - 2020-09-25

### Changed

- Changed data provider generated `it` blocks have proper file names and line numbers ([#4](https://github.com/athena-framework/spec/pull/4)) (George Dietrich)

## [0.2.0] - 2020-08-08

### Changed

- **Breaking:** require [data providers](https://athenaframework.org/Spec/TestCase/DataProvider/) methods to declare a return type of `Hash`, `NamedTuple`, `Tuple`, or `Array` ([#3](https://github.com/athena-framework/spec/pull/3)) (George Dietrich)
- Changed data provider generated `it` blocks to include the key/index ([#2](https://github.com/athena-framework/spec/pull/2)) (George Dietrich)

## [0.1.0] - 2020-08-06

_Initial release._

[0.3.0]: https://github.com/athena-framework/spec/releases/tag/v0.3.0
[0.2.6]: https://github.com/athena-framework/spec/releases/tag/v0.2.6
[0.2.5]: https://github.com/athena-framework/spec/releases/tag/v0.2.5
[0.2.4]: https://github.com/athena-framework/spec/releases/tag/v0.2.4
[0.2.3]: https://github.com/athena-framework/spec/releases/tag/v0.2.3
[0.2.2]: https://github.com/athena-framework/spec/releases/tag/v0.2.2
[0.2.1]: https://github.com/athena-framework/spec/releases/tag/v0.2.1
[0.2.0]: https://github.com/athena-framework/spec/releases/tag/v0.2.0
[0.1.0]: https://github.com/athena-framework/spec/releases/tag/v0.1.0
