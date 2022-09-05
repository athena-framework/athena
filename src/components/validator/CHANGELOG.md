# Changelog

## [0.2.1] - 2022-09-05

### Added

- Add support for exclusive end support to `AVD::Constraints::Range` ([#184](https://github.com/athena-framework/athena/pull/184)) (George Dietrich)

### Changed

- Include allowed MIME types within `AVD::Constraints::Image` if they were customized ([#183](https://github.com/athena-framework/athena/pull/183)) (George Dietrich)
- **Breaking:** ensure parameter names defined on interfaces match the implementation ([#188](https://github.com/athena-framework/athena/pull/188)) (George Dietrich)

### Fixed

- Fix some file size factorization edge cases in `AVD::Constraints::File` ([#182](https://github.com/athena-framework/athena/pull/182)) (George Dietrich)
- Fix duplicating constraints due to Crystal generics bug ([#192](https://github.com/athena-framework/athena/pull/192)) (George Dietrich)

## [0.2.0] - 2022-05-14

### Added

- Add the [AVD::Constraints::File](https://athenaframework.org/Validator/Constraints/File/) constraint ([#153](https://github.com/athena-framework/athena/pull/153)) (George Dietrich)
- Allow `AVD::Spec::MockValidator` to dynamically configure returned violations ([#155](https://github.com/athena-framework/athena/pull/155), [#157](https://github.com/athena-framework/athena/pull/157)) (George Dietrich)
- Add the [AVD::Constraints::Image](https://athenaframework.org/Validator/Constraints/Image/) constraint ([#153](https://github.com/athena-framework/athena/pull/153)) (George Dietrich)
- Add getting started documentation to API docs ([#172](https://github.com/athena-framework/athena/pull/172)) (George Dietrich)

### Changed

- **Breaking:** make `AVD::ConstraintValidator` classes ([#154](https://github.com/athena-framework/athena/pull/154)) (George Dietrich)
- **Breaking:** `AVD::ExecutionContext` is no longer a generic type ([#156](https://github.com/athena-framework/athena/pull/156)) (George Dietrich)
- Update `assert_violation` to use a clearer failure message if no violations were found ([#153](https://github.com/athena-framework/athena/pull/153)) (George Dietrich)
- Update `AVD::Constraints::ISIN` to use the validator off the context versus an ivar ([#155](https://github.com/athena-framework/athena/pull/155)) (George Dietrich)
- Update minimum `crystal` version to `~> 1.4.0` ([#169](https://github.com/athena-framework/athena/pull/169)) (George Dietrich)

### Removed

- **Breaking:** removed `AVD::Spec::MockValidator#violations=` ([#155](https://github.com/athena-framework/athena/pull/155)) (George Dietrich)

### Fixed

- Fix `AVD::Violation::ConstraintViolation` not comparing correctly ([#153](https://github.com/athena-framework/athena/pull/153)) (George Dietrich)
- Ensure only `Indexable` types can be used with `AVD::Constraints::Unique` ([#168](https://github.com/athena-framework/athena/pull/168)) (George Dietrich)

## [0.1.7] - 2021-12-27

_First release a part of the monorepo._

### Fixed

- Fix callback constraint methods being incorrectly added as getters ([#132](https://github.com/athena-framework/athena/pull/132)) (George Dietrich)

## [0.1.6] - 2021-12-13

### Fixed

- Fix `AVD::Validatable` not working when included into parent types ([#16](https://github.com/athena-framework/validator/pull/16)) (George Dietrich)

## [0.1.5] - 2021-10-30

### Added

- Add `VERSION` constant to `Athena::Validator` namespace ([#12](https://github.com/athena-framework/validator/pull/12)) (George Dietrich)

### Fixed

- Fix incorrect type restriction on validator factory ([#12](https://github.com/athena-framework/validator/pull/12)) (George Dietrich)
- Fix incorrect link within the docs ([#14](https://github.com/athena-framework/validator/pull/14)) (George Dietrich)

## [0.1.4] - 2021-01-30

### Changed

- Finish migration to [MkDocs](https://mkdocstrings.github.io/crystal/) ([#10](https://github.com/athena-framework/validator/pull/10), [#11](https://github.com/athena-framework/validator/pull/11)) (George Dietrich)

## [0.1.3] - 2020-12-07

### Changed

- Update `crystal` version to allow version greater than `1.0.0` ([#9](https://github.com/athena-framework/validator/pull/9)) (George Dietrich

## [0.1.2] - 2020-11-25

### Added

- Add the [AVD::Constraints::Choice](https://athenaframework.org/Validator/Constraints/Choice/) constraint ([#7](https://github.com/athena-framework/validator/pull/7)) (George Dietrich)

### Changed

- Allow setting violations directly on mock validators ([#7](https://github.com/athena-framework/validator/pull/7)) (George Dietrich)

## [0.1.1] - 2020-11-08

### Fixed

- Fix compiler error due to less strict `abstract def` implemenations ([#6](https://github.com/athena-framework/validator/pull/6)) (George Dietrich)

## [0.1.0] - 2020-10-17

_Initial release._

[0.2.1]: https://github.com/athena-framework/validator/releases/tag/v0.2.1
[0.2.0]: https://github.com/athena-framework/validator/releases/tag/v0.2.0
[0.1.7]: https://github.com/athena-framework/validator/releases/tag/v0.1.7
[0.1.6]: https://github.com/athena-framework/validator/releases/tag/v0.1.6
[0.1.5]: https://github.com/athena-framework/validator/releases/tag/v0.1.5
[0.1.4]: https://github.com/athena-framework/validator/releases/tag/v0.1.4
[0.1.3]: https://github.com/athena-framework/validator/releases/tag/v0.1.3
[0.1.2]: https://github.com/athena-framework/validator/releases/tag/v0.1.2
[0.1.1]: https://github.com/athena-framework/validator/releases/tag/v0.1.1
[0.1.0]: https://github.com/athena-framework/validator/releases/tag/v0.1.0
